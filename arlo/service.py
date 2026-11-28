"""Private stdio between the trusted shell and its settings service."""

import json
import os
from pathlib import Path
import queue
import sqlite3
import sys
import threading

from provider import propose
from store import Store


class Service:
    def __init__(self, store, events):
        self.store = store
        self.events = events
        self.home = False
        self.epoch = 0
        self.serial = 0
        self.thread = store.db.execute(
            "SELECT thread FROM selection WHERE id=1"
        ).fetchone()[0]
        self.workers = {}

    def emit(self, error=""):
        with self.store.transaction():
            data = self.store.snapshot(self.thread if self.home else None)
        print(
            json.dumps(dict(data, epoch=self.epoch, serial=self.serial, error=error)),
            flush=True,
        )

    def infer(self, task, request, height, history, stop):
        try:
            operation = propose(request, height, history, stop)
            self.events.put(("result", (task, operation, "")))
        except Exception as exc:
            message = (
                str(exc)
                if isinstance(exc, ValueError)
                else "Local inference failed. Retry the request."
            )
            self.events.put(("result", (task, None, message)))

    def finish(self, task, operation, error):
        self.workers.pop(task, None)
        try:
            with self.store.transaction():
                if error:
                    raise ValueError(error)
                self.store.finish(task, operation)
        except ValueError as exc:
            with self.store.transaction():
                self.store.db.execute(
                    "UPDATE tasks SET state='failed',result=? WHERE id=? AND state='working' AND owner=?",
                    (str(exc), task, self.store.owner),
                )

    def handle(self, msg):
        if not isinstance(msg, dict):
            raise ValueError("Invalid shell request.")
        self.serial = msg.get("serial", 0)
        op = msg.get("action")
        if op == "context":
            self.home = msg.get("space") == "home"
            self.epoch = msg["epoch"]
            return
        if op == "resize":  # Direct shell control, independent of agent permissions.
            with self.store.transaction():
                self.store.set_height(msg.get("height"))
            return
        if not self.home or msg.get("epoch") != self.epoch:
            raise ValueError("Arlo is available in Home.")
        job = None
        db = self.store.db
        with self.store.transaction():
            if op == "new":
                self.thread = db.execute("INSERT INTO threads DEFAULT VALUES").lastrowid
                db.execute("UPDATE selection SET thread=?", (self.thread,))
            elif op == "open" and self.store.thread_exists(msg.get("thread")):
                self.thread = msg["thread"]
                db.execute("UPDATE selection SET thread=?", (self.thread,))
            elif msg.get("thread") != self.thread:
                raise ValueError("Reopen the conversation and try again.")
            elif op == "draft" and isinstance(msg.get("text"), str):
                db.execute(
                    "UPDATE threads SET draft=? WHERE id=?",
                    (msg["text"][:1000], self.thread),
                )
            elif op in ("ask", "retry"):
                request = msg.get("text")
                if op == "retry":
                    row = db.execute(
                        """SELECT request FROM tasks WHERE id=? AND thread=?
                        AND state IN ('failed','interrupted','cancelled')""",
                        (msg.get("id"), self.thread),
                    ).fetchone()
                    if not row:
                        raise ValueError("This activity cannot be retried.")
                    request = row["request"]
                task, height, history = self.store.begin(
                    self.thread, request, clear_draft=(op == "ask")
                )
                job = task, request, height, history
            elif op == "undo":
                self.store.undo(msg.get("id"), self.thread)
            elif op == "cancel":
                changed = db.execute(
                    """UPDATE tasks SET state='cancelled',result='Cancelled before applying a change.'
                    WHERE id=? AND thread=? AND state='working'""",
                    (msg.get("id"), self.thread),
                ).rowcount
                if not changed:
                    raise ValueError("This activity already finished.")
                stop = self.workers.get(msg["id"])
                if stop:
                    stop.set()
            else:
                raise ValueError("Unsupported shell action.")
        if job:
            stop = threading.Event()
            self.workers[job[0]] = stop
            threading.Thread(target=self.infer, args=(*job, stop), daemon=True).start()


def main():
    os.umask(0o077)
    directory = (
        Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
        / "SpacesOS"
        / "arlo"
    )
    events = queue.Queue()
    service = Service(Store(directory), events)

    def read():
        for line in sys.stdin:
            events.put(("input", line))
        events.put(("stop", None))

    threading.Thread(target=read, daemon=True).start()
    db = service.store.db
    version = db.execute("PRAGMA data_version").fetchone()[0]
    service.emit()
    try:
        while True:
            try:
                kind, payload = events.get(timeout=0.35)
            except queue.Empty:
                changed = db.execute("PRAGMA data_version").fetchone()[0]
                if changed != version:
                    version = changed
                    service.emit()
                continue
            if kind == "stop":
                break
            try:
                if kind == "result":
                    service.finish(*payload)
                else:
                    service.handle(json.loads(payload))
                service.emit()
            except (ValueError, KeyError, TypeError) as exc:
                service.emit(
                    str(exc)
                    if isinstance(exc, ValueError)
                    else "Invalid shell request."
                )
            except sqlite3.Error:
                service.emit(
                    "The preference could not be saved. Retry after checking disk access."
                )
    finally:
        for stop in service.workers.values():
            stop.set()


if __name__ == "__main__":
    main()
