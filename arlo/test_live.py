"""Opt-in local model and service restart smoke check. Run inside nix develop."""

import json
import os
from pathlib import Path
import queue
import subprocess
import sys
import tempfile
import threading
import unittest


class Client:
    def __init__(self, directory, *, offline=False):
        env = dict(os.environ, XDG_STATE_HOME=directory)
        if offline:
            env["PATH"] = directory
        self.process = subprocess.Popen(
            [sys.executable, "-B", Path(__file__).with_name("service.py")],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            text=True,
            env=env,
        )
        self.lines = queue.Queue()
        self.epoch = 0
        self.state = {}

        def read():
            for line in self.process.stdout:
                self.lines.put(json.loads(line))
            self.lines.put(None)

        threading.Thread(target=read, daemon=True).start()
        self.wait(lambda data: "height" in data)
        self.context("home")

    def wait(self, condition):
        while True:
            self.state = self.lines.get(timeout=60)
            if self.state is None:
                raise RuntimeError("Settings service closed unexpectedly")
            if condition(self.state):
                return self.state

    def send(self, action, **values):
        msg = dict(epoch=self.epoch, thread=self.state.get("thread", 1), action=action)
        self.process.stdin.write(json.dumps(dict(msg, **values)) + "\n")
        self.process.stdin.flush()

    def context(self, space):
        self.epoch += 1
        self.send("context", space=space)
        return self.wait(lambda data: data["epoch"] == self.epoch)

    def finish(self, action, **values):
        count = len(self.state["tasks"])
        self.send(action, **values)
        return self.wait(
            lambda data: (
                len(data.get("tasks", [])) > count
                and data["tasks"][-1]["state"] != "working"
            )
        )

    def close(self):
        if self.process.poll() is None:
            self.process.stdin.close()
            self.process.wait(timeout=5)
        self.process.stdout.close()


class LiveModel(unittest.TestCase):
    def test_followup_recovery_retry_scope_and_undo(self):
        with tempfile.TemporaryDirectory() as state:

            def start(offline=False):
                client = Client(state, offline=offline)
                self.addCleanup(client.close)
                return client

            client = start(offline=True)
            failed = client.finish("ask", text="Make the dock 80 pixels high")["tasks"][
                -1
            ]
            self.assertEqual(failed["state"], "failed")
            self.assertEqual(client.state["height"], 64)
            client.close()
            client = start()
            resized = client.finish("retry", id=failed["id"])
            self.assertEqual(resized["height"], 80)
            self.assertEqual(resized["tasks"][-1]["state"], "completed")
            client.send("draft", text="Actually, use 64")
            client.wait(lambda data: data.get("draft") == "Actually, use 64")
            client.close()
            client = start()
            self.assertEqual(
                (client.state["height"], client.state["draft"]),
                (80, "Actually, use 64"),
            )
            client.send("ask", text=client.state["draft"])
            client.wait(lambda data: data["tasks"][-1]["state"] == "working")
            self.assertNotIn("tasks", client.context("ithos"))
            shared = client.wait(lambda data: data["height"] == 64)
            self.assertNotIn("tasks", shared)
            task = client.context("home")["tasks"][-1]
            self.assertEqual((task["context"], task["state"]), ("home", "completed"))
            read = client.finish("ask", text="What size is it now?")
            self.assertEqual(read["tasks"][-1]["result"], "The dock is 64 px high.")
            client.send("undo", id=task["id"])
            client.wait(lambda data: data["height"] == 80)
            blocked = client.finish("ask", text="Open a terminal")
            self.assertEqual(blocked["tasks"][-1]["state"], "failed")
            self.assertEqual(blocked["height"], 80)
            client.send("ask", text="Make the dock 56 pixels high")
            pending = client.wait(lambda data: data["tasks"][-1]["state"] == "working")[
                "tasks"
            ][-1]
            client.send("cancel", id=pending["id"])
            client.wait(lambda data: data["tasks"][-1]["state"] == "cancelled")
            self.assertEqual(client.state["height"], 80)


if __name__ == "__main__":
    unittest.main()
