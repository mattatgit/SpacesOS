"""Run the SDK tests on a disposable Synapse bound only to loopback."""
from ipc import check_service, check_reconnect
from contextlib import contextmanager
import json
import os
from pathlib import Path
import secrets
import socket
import subprocess
import tempfile
import time
from urllib.request import Request, urlopen

with tempfile.TemporaryDirectory(prefix="spaces-matrix-test-") as tmp:
    os.umask(0o077)
    os.environ.update(XDG_DATA_HOME=tmp + "/data", XDG_CONFIG_HOME=tmp + "/config",
                      XDG_RUNTIME_DIR=tmp + "/runtime", GNOME_KEYRING_CONTROL=tmp + "/keyring",
                      SPIKE_PROFILE_ROOT=tmp + "/data/SpacesOS/matrix")
    Path(os.environ["XDG_RUNTIME_DIR"]).mkdir(mode=0o700)
    subprocess.run(["gnome-keyring-daemon", "--unlock", "--components=secrets"],
                   input=secrets.token_bytes(32).hex().encode(), stdout=subprocess.DEVNULL, check=True)
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        port = sock.getsockname()[1]
    url = f"http://127.0.0.1:{port}"
    config = Path(tmp) / "homeserver.yaml"
    config.write_text(f"""
server_name: localhost
report_stats: false
public_baseurl: {url}/
listeners:
  - port: {port}
    bind_addresses: ['127.0.0.1']
    type: http
    tls: false
    resources: [{{names: [client]}}]
database: {{name: sqlite3, args: {{database: '{tmp}/test.db'}}}}
media_store_path: '{tmp}/media'
signing_key_path: '{tmp}/signing.key'
enable_registration: true
enable_registration_without_verification: true
federation_domain_whitelist: []
rc_login: {{account: {{per_second: 100, burst_count: 100}}}}
rc_message: {{per_second: 100, burst_count: 100}}
""")
    @contextmanager
    def start_server():
        with subprocess.Popen(["synapse_homeserver", "-c", str(config)], cwd=tmp,
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) as child:
            try:
                yield child
            finally:
                child.terminate()

    with start_server() as server:
        try:
            for _ in range(300):
                if server.poll() is not None:
                    raise RuntimeError("Disposable Synapse failed to start")
                try:
                    with urlopen(url + "/_matrix/client/versions", timeout=1):
                        break
                except OSError:
                    time.sleep(0.1)
            password = secrets.token_urlsafe(32)
            req = Request(url + "/_matrix/client/v3/register", headers={"Content-Type": "application/json"},
                          data=json.dumps(dict(username="fixture", password=password, inhibit_login=True,
                                               auth={"type": "m.login.dummy"})).encode())
            with urlopen(req) as response:
                assert response.status == 200
            subprocess.run(["cargo", "test", "--locked", "--manifest-path", "messaging/Cargo.toml", "--", "--include-ignored"],
                           env=dict(os.environ, SPIKE_SERVER=url, SPIKE_PASSWORD=password), check=True, timeout=240)
            binary = Path(os.environ["CARGO_TARGET_DIR"]).resolve() / "debug/spaces-messaging"
            check_service(binary)

            def stop_server():
                server.terminate()
                server.wait(timeout=10)

            check_reconnect(binary, stop_server, start_server)
            print("Verified service restart, private IPC, media preview/save and idempotent retry.")
        finally:
            server.terminate()
