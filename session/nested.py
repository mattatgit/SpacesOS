"""Own one GNOME-hosted Spaces desktop, its profile and its activation socket."""

import argparse
import contextlib
import fcntl
import os
from pathlib import Path
import signal
import socket
import subprocess
import sys
import tempfile
import time


def acquire_or_activate(lock, address):
    """Serialize simultaneous starts, including a click while the owner is starting."""
    deadline = time.monotonic() + 15
    token = os.environ.get("XDG_ACTIVATION_TOKEN") or os.environ.get(
        "DESKTOP_STARTUP_ID", ""
    )
    with socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM) as client:
        client.settimeout(1)
        while True:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                return True
            except BlockingIOError:
                pass
            try:
                client.sendto(token.encode(), str(address))
                return False
            except (FileNotFoundError, ConnectionRefusedError):
                if time.monotonic() >= deadline:
                    raise RuntimeError(
                        "The existing Spaces desktop is still starting or closing."
                    )
                time.sleep(0.05)


def run_desktop(parent, runtime, home, activation, profile_lock):
    env = os.environ.copy()
    for key in (
        "DISPLAY",
        "XAUTHORITY",
        "SWAYSOCK",
        "I3SOCK",
        "DBUS_SESSION_BUS_ADDRESS",
        "DBUS_STARTER_ADDRESS",
        "DBUS_STARTER_BUS_TYPE",
        "SPACES_ACTIVATION_FD",
        "SPACES_PROFILE_LOCK_FD",
        "AT_SPI_BUS_ADDRESS",
        "GNOME_KEYRING_CONTROL",
        "SSH_AUTH_SOCK",
        "SESSION_MANAGER",
        "GIO_LAUNCHED_DESKTOP_FILE",
        "GIO_LAUNCHED_DESKTOP_FILE_PID",
        "GDK_SCALE",
        "GDK_DPI_SCALE",
        "QT_SCALE_FACTOR",
        "QT_SCREEN_SCALE_FACTORS",
    ):
        env.pop(key, None)
    env.update(
        HOME=str(home),
        XDG_CONFIG_HOME=str(home / ".config"),
        XDG_DATA_HOME=str(home / ".local/share"),
        XDG_STATE_HOME=str(home / ".local/state"),
        XDG_CACHE_HOME=str(home / ".cache"),
        XDG_RUNTIME_DIR=str(runtime),
        WAYLAND_DISPLAY=str(parent),
        WLR_BACKENDS="wayland",
        WLR_WL_OUTPUTS="1",
        LABWC_UPDATE_ACTIVATION_ENV="0",
        SPACES_NESTED="1",
    )
    for key in (
        "HOME",
        "XDG_DATA_HOME",
        "XDG_STATE_HOME",
        "XDG_CONFIG_HOME",
        "XDG_CACHE_HOME",
    ):
        Path(env[key]).mkdir(mode=0o700, parents=True, exist_ok=True)
    runtime.mkdir(mode=0o700)
    fds = ()
    if activation:
        # dbus-run-session keeps the profile locked even if this supervisor exits.
        fds = (activation.fileno(), profile_lock.fileno())
        env["SPACES_PROFILE_LOCK_FD"] = str(profile_lock.fileno())
        env["SPACES_ACTIVATION_FD"] = str(activation.fileno())
    compositor = env["SPACES_NESTED_LABWC"]
    config = Path(__file__).resolve().parent
    # dbus-run-session supplies a fresh bus to labwc and every shell client.
    command = [
        "dbus-run-session",
        "--",
        compositor,
        "-C",
        str(config),
        "-S",
        "spaces-shell-client",
    ]
    with subprocess.Popen(
        command,
        env=env,
        cwd=home,
        stdin=subprocess.DEVNULL,
        pass_fds=fds,
        start_new_session=True,
    ) as process:

        def stop(signum, frame):
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass

        for sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
            signal.signal(sig, stop)
        return process.wait()


@contextlib.contextmanager
def session_directory(base, prefix):
    directory = Path(tempfile.mkdtemp(prefix=prefix, dir=base))
    try:
        yield directory
    finally:
        # The document portal and GVfs can still be unmounting after the private
        # bus closes. Never traverse their mounts or the persisted test profile.
        for _ in range(30):
            result = subprocess.run(
                ["rm", "-rf", "--one-file-system", "--", directory], capture_output=True
            )
            if result.returncode == 0:
                break
            time.sleep(0.1)
        else:
            print(f"Spaces could not finish cleaning {directory}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--disposable", action="store_true")
    args = parser.parse_args()
    os.umask(0o077)
    host_runtime = Path(os.environ["XDG_RUNTIME_DIR"])
    parent = host_runtime / os.environ["WAYLAND_DISPLAY"]
    if not parent.is_socket():
        raise RuntimeError("Open Spaces from a running Wayland desktop.")
    with contextlib.ExitStack() as stack:
        activation = None
        lock = None
        if args.disposable:
            temp = stack.enter_context(session_directory(host_runtime, "spaces-test-"))
            home = temp / "home"
        else:
            control = host_runtime / "spaces-nested"
            control.mkdir(mode=0o700, exist_ok=True)
            lock = stack.enter_context((control / "session.lock").open("a"))
            address = control / "activate"
            if not acquire_or_activate(lock, address):
                return 0
            address.unlink(missing_ok=True)
            activation = stack.enter_context(
                socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
            )
            activation.bind(str(address))
            stack.callback(address.unlink, missing_ok=True)
            temp = stack.enter_context(session_directory(control, "run-"))
            state = Path(
                os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state"
            )
            home = state / "SpacesOS" / "nested"
        return run_desktop(parent, temp / "runtime", home, activation, lock)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (KeyError, OSError, RuntimeError) as error:
        sys.exit(f"Spaces could not open the nested desktop: {error}")
