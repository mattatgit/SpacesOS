"""Focused tests for permissions, transaction boundaries and stale work."""

import queue
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from service import Service
from store import SCOPE, Store


class ActivityTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.path = Path(directory.name)
        self.store = Store(self.path)
        self.addCleanup(self.store.db.close)
        self.service = Service(self.store, queue.Queue())
        self.context("home", 1)
        self.thread = self.service.thread

    def context(self, space, epoch):
        self.service.handle({"action": "context", "space": space, "epoch": epoch})

    def ask(self, request):
        with self.store.transaction():
            return self.store.begin(self.thread, request)[0]

    def send(self, action, **kwargs):
        self.service.handle(
            dict(action=action, epoch=self.service.epoch, thread=self.thread, **kwargs)
        )

    def test_undo_after_read_but_never_over_a_newer_direct_resize(self):
        first = self.ask("80 please")
        self.service.finish(first, {"op": "set", "height": 80}, "")
        read = self.ask("What size?")
        self.service.finish(read, {"op": "read"}, "")
        self.assertTrue(self.store.snapshot(self.thread)["tasks"][0]["canUndo"])
        self.send("undo", id=first)
        self.assertEqual(self.store.preference()["height"], 64)
        second = self.ask("80 again")
        self.service.finish(second, {"op": "set", "height": 80}, "")
        self.send("resize", height=72)
        self.send("resize", height=80)
        with self.assertRaisesRegex(ValueError, "changed since"):
            self.send("undo", id=second)
        self.assertEqual(self.store.preference()["height"], 80)

    def test_shared_context_has_no_personal_operations_or_records(self):
        task = self.ask("set 80")
        self.context("ithos", 2)
        for op in ["ask", "draft", "open", "new", "cancel", "undo", "retry"]:
            with self.assertRaisesRegex(ValueError, "Home"):
                self.send(op, id=task)
        self.service.finish(task, {"op": "set", "height": 80}, "")
        with patch("builtins.print") as output:
            self.service.emit()
        self.assertNotIn("tasks", output.call_args.args[0])
        self.assertNotIn("set 80", output.call_args.args[0])
        self.context("home", 3)
        row = self.store.snapshot(self.thread)["tasks"][0]
        self.assertEqual(
            (row["context"], row["scope"], row["state"]), ("home", SCOPE, "completed")
        )
        with self.assertRaisesRegex(ValueError, "Home"):
            self.service.handle(
                dict(action="ask", epoch=1, thread=self.thread, text="stale")
            )

    def test_cancel_race_and_validation(self):
        task = self.ask("set 80")
        self.send("cancel", id=task)
        self.service.finish(task, {"op": "set", "height": 80}, "")
        self.assertEqual(self.store.preference()["height"], 64)
        for operation in (
            {"op": "resize", "height": 56},
            {"op": "set", "height": True},
            {"op": "set", "height": 62},
            {"op": "set", "height": 80, "scope": "other"},
        ):
            task = self.ask("invalid")
            self.service.finish(task, operation, "")
            self.assertEqual(
                self.store.snapshot(self.thread)["tasks"][-1]["state"], "failed"
            )
            self.assertEqual(self.store.preference()["height"], 64)
        task = self.ask("stale")
        self.send("resize", height=56)
        self.service.finish(task, {"op": "set", "height": 72}, "")
        self.assertEqual(self.store.preference()["height"], 56)
        self.assertEqual(
            self.store.snapshot(self.thread)["tasks"][-1]["state"], "failed"
        )

    def test_recovery_drafts_history_and_no_replay(self):
        self.send("draft", text="private draft")
        self.send("new")
        new = self.service.thread
        self.assertNotEqual(new, self.thread)
        self.service.handle(dict(action="open", epoch=1, thread=self.thread))
        self.assertEqual(self.store.snapshot(self.thread)["draft"], "private draft")
        task = self.ask("interrupted")
        with self.store.transaction():
            self.store.db.execute(
                "UPDATE tasks SET owner='old:99999999:0' WHERE id=?", (task,)
            )
        fresh = Store(self.path)
        self.addCleanup(fresh.db.close)
        recovered = Service(fresh, queue.Queue())
        self.assertEqual(recovered.thread, self.thread)
        self.assertEqual(
            fresh.snapshot(self.thread)["tasks"][-1]["state"], "interrupted"
        )
        self.assertEqual(fresh.preference()["height"], 64)


if __name__ == "__main__":
    unittest.main()
