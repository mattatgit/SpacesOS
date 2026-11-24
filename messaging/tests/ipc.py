"""Exercise the same private pipe as the QML sidebar against the verified test account."""
import json
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
from threading import Timer


def check_service(binary):
    with TemporaryDirectory() as tmp:
        dest = Path(tmp) / "download.png"
        with subprocess.Popen([binary, "serve"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True) as proc:
            deadline = Timer(90, proc.kill)
            deadline.start()

            def request(serial, **command):
                proc.stdin.write(json.dumps(dict(serial=serial, **command)) + "\n")
                proc.stdin.flush()
                for line in proc.stdout:
                    event = json.loads(line)
                    if event["type"] == "unavailable":
                        raise AssertionError(event["message"])
                    if event.get("serial") == serial and event["type"] == "reply":
                        return event
                raise AssertionError("Service exited before reply")
            try:
                page = request(1, op="history")["data"]
                image = next(row for row in page["items"] if row["kind"] == "image")
                assert request(2, op="preview", event=image["id"])["data"].startswith("data:image/jpeg;base64,")
                assert "error" not in request(3, op="save", event=image["id"], url=dest.as_uri())
                assert dest.read_bytes() == Path("messaging/tests/pixel.png").read_bytes()
                assert "error" in request(4, op="save", event=image["id"], url=dest.as_uri())
                for serial in [5, 6]:
                    assert "error" not in request(serial, op="text", body="Delivery check", txn="same-send")
                assert "error" not in request(7, op="upload", url=dest.as_uri(), txn="file-reply")
                rows = request(8, op="history")["data"]["items"]
                assert sum(row["body"] == "Delivery check" for row in rows) == 1
                assert any(row["body"] == "download.png" for row in rows)
            finally:
                proc.stdin.close()
                try:
                    proc.wait(timeout=15)
                finally:
                    deadline.cancel()


def check_reconnect(binary, stop_server, start_server):
    """Keep the service process alive while its remote endpoint goes away."""
    with subprocess.Popen([binary, "serve"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True) as proc:
        deadline = Timer(120, proc.kill)
        deadline.start()

        def wait_for(kind):
            for line in proc.stdout:
                message = json.loads(line)
                if message["type"] == "unavailable":
                    raise AssertionError(message["message"])
                if message["type"] == kind:
                    return message
            raise AssertionError("Service exited during reconnect test")

        try:
            wait_for("changed")
            stop_server()
            wait_for("offline")
            with start_server():
                wait_for("changed")
                proc.stdin.write('{"op":"history","serial":1}\n')
                proc.stdin.flush()
                rows = wait_for("reply")["data"]["items"]
                assert any(row["body"] == "Delivery check" for row in rows)
        finally:
            proc.stdin.close()
            try:
                proc.wait(timeout=15)
            finally:
                deadline.cancel()
