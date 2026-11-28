"""Transactional, user-private storage for the personal shell preference and activity."""

from contextlib import contextmanager
import os
from pathlib import Path
import sqlite3

SCOPE = "personal-shell/dock-height"


def supported(value):
    return type(value) is int and (value == 56 or 64 <= value <= 80)


class Store:
    def __init__(self, directory):
        directory.mkdir(parents=True, exist_ok=True, mode=0o700)
        self.db = sqlite3.connect(
            directory / "activity.sqlite", isolation_level=None, timeout=4
        )
        self.db.row_factory = sqlite3.Row
        self.db.execute("PRAGMA journal_mode=WAL")
        self.db.execute("PRAGMA foreign_keys=ON")
        self.db.executescript("""
            CREATE TABLE IF NOT EXISTS preference (
              id INTEGER PRIMARY KEY CHECK(id=1), height INTEGER NOT NULL, revision INTEGER NOT NULL);
            INSERT OR IGNORE INTO preference VALUES (1,64,0);
            CREATE TABLE IF NOT EXISTS threads (id INTEGER PRIMARY KEY, draft TEXT NOT NULL DEFAULT '');
            INSERT OR IGNORE INTO threads(id) VALUES (1);
            CREATE TABLE IF NOT EXISTS selection (
              id INTEGER PRIMARY KEY CHECK(id=1), thread INTEGER NOT NULL REFERENCES threads(id));
            INSERT OR IGNORE INTO selection VALUES (1,1);
            CREATE TABLE IF NOT EXISTS tasks (
              id INTEGER PRIMARY KEY, thread INTEGER NOT NULL REFERENCES threads(id),
              request TEXT NOT NULL, context TEXT NOT NULL, scope TEXT NOT NULL,
              state TEXT NOT NULL, result TEXT NOT NULL, owner TEXT NOT NULL,
              base_revision INTEGER NOT NULL, previous INTEGER, applied_revision INTEGER);
        """)
        # A process identity survives PID reuse and is distinct across boots.
        self.boot = Path("/proc/sys/kernel/random/boot_id").read_text().strip()
        self.owner = self.process_id(os.getpid())
        with self.transaction():
            for row in self.db.execute(
                "SELECT DISTINCT owner FROM tasks WHERE state='working'"
            ).fetchall():
                owner = row["owner"]
                if self.process_id(int(owner.split(":")[1])) != owner:
                    self.db.execute(
                        """UPDATE tasks SET state='interrupted',result=?
                        WHERE state='working' AND owner=?""",
                        (
                            "Spaces closed before this request completed. You can retry it.",
                            owner,
                        ),
                    )

    def process_id(self, pid):
        try:
            stat = Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()
            if stat[0] != "Z":
                return f"{self.boot}:{pid}:{stat[19]}"
        except (FileNotFoundError, ProcessLookupError):
            pass
        return ""

    @contextmanager
    def transaction(self):
        self.db.execute("BEGIN IMMEDIATE")
        try:
            yield
            self.db.commit()
        except BaseException:
            self.db.rollback()
            raise

    def preference(self):
        return self.db.execute("SELECT height,revision FROM preference").fetchone()

    def set_height(self, value):
        if not supported(value):
            raise ValueError("Choose 56 px or a whole number from 64 to 80 px.")
        self.db.execute(
            "UPDATE preference SET height=?, revision=revision+1 WHERE height<>?",
            (value, value),
        )
        return self.preference()

    def thread_exists(self, thread):
        return (
            type(thread) is int
            and self.db.execute(
                "SELECT 1 FROM threads WHERE id=?", (thread,)
            ).fetchone()
        )

    def snapshot(self, thread):
        pref = self.preference()
        data = {"height": pref["height"], "revision": pref["revision"]}
        if thread is None:
            return data
        data["thread"] = thread
        data["draft"] = self.db.execute(
            "SELECT draft FROM threads WHERE id=?", (thread,)
        ).fetchone()[0]
        data["threads"] = [
            dict(row)
            for row in self.db.execute("""
            SELECT id,coalesce((SELECT substr(request,1,45) FROM tasks WHERE thread=t.id
            ORDER BY id LIMIT 1),'New conversation') AS title FROM threads t ORDER BY id DESC""")
        ]
        data["tasks"] = [
            dict(row)
            for row in self.db.execute(
                """
            SELECT id,request,context,scope,state,result,
              coalesce(applied_revision=? AND state='completed',0) AS canUndo
            FROM tasks WHERE thread=? ORDER BY id""",
                (pref["revision"], thread),
            )
        ]
        return data

    def begin(self, thread, request, clear_draft=True):
        if not isinstance(request, str) or not 1 <= len(request.strip()) <= 1000:
            raise ValueError("Enter a request of up to 1,000 characters.")
        if self.db.execute(
            "SELECT 1 FROM tasks WHERE thread=? AND state='working'", (thread,)
        ).fetchone():
            raise ValueError("Finish or cancel the current request first.")
        pref = self.preference()
        task = self.db.execute(
            """INSERT INTO tasks(thread,request,context,scope,state,result,owner,base_revision)
            VALUES (?,?,'home',?,'working','',?,?)""",
            (thread, request.strip(), SCOPE, self.owner, pref["revision"]),
        ).lastrowid
        if clear_draft:
            self.db.execute("UPDATE threads SET draft='' WHERE id=?", (thread,))
        history = [
            dict(row)
            for row in self.db.execute(
                """SELECT request,result FROM tasks
            WHERE thread=? AND id<? ORDER BY id DESC LIMIT 4""",
                (thread, task),
            )
        ][::-1]
        return task, pref["height"], history

    def undo(self, task, thread):
        row = self.db.execute(
            "SELECT * FROM tasks WHERE id=? AND thread=? AND context='home' AND scope=?",
            (task, thread, SCOPE),
        ).fetchone()
        if (
            not row
            or row["state"] != "completed"
            or row["applied_revision"] != self.preference()["revision"]
        ):
            raise ValueError(
                "The dock has changed since that activity. Its earlier size cannot be restored by Undo."
            )
        height = self.set_height(row["previous"])["height"]
        result = f"Restored the dock to {height} px."
        self.db.execute(
            "UPDATE tasks SET state='undone',result=result || ' ' || ? WHERE id=?",
            (result, task),
        )
        return result

    def finish(self, task, operation):
        row = self.db.execute("SELECT * FROM tasks WHERE id=?", (task,)).fetchone()
        if not row or row["state"] != "working" or row["owner"] != self.owner:
            return
        if (row["context"], row["scope"]) != ("home", SCOPE):
            raise ValueError("This activity cannot change the personal shell.")
        if not isinstance(operation, dict):
            raise ValueError("The provider returned an invalid operation.")
        op = operation.get("op")
        if set(operation) != ({"op", "height"} if op == "set" else {"op"}):
            raise ValueError("The provider returned unsupported parameters.")
        pref = self.preference()
        previous = revision = None
        if op == "read":
            result = f"The dock is {pref['height']} px high."
        elif op in ("set", "undo"):
            if row["base_revision"] != pref["revision"]:
                raise ValueError(
                    "The dock changed while Arlo was working. Retry using the current size."
                )
            if op == "set":
                updated = self.set_height(operation["height"])
                if updated["revision"] == pref["revision"]:
                    result = f"The dock is already {updated['height']} px high."
                else:
                    previous, revision = pref["height"], updated["revision"]
                    result = (
                        f"Changed the dock from {previous} to {updated['height']} px."
                    )
            else:
                target = self.db.execute(
                    """SELECT id FROM tasks WHERE thread=? AND state='completed'
                    AND applied_revision=?""",
                    (row["thread"], pref["revision"]),
                ).fetchone()
                if not target:
                    raise ValueError(
                        "There is no applicable dock change to undo in this conversation."
                    )
                result = self.undo(target["id"], row["thread"])
        else:
            raise ValueError(
                "Arlo can read or change the dock height, or undo an applicable change."
            )
        self.db.execute(
            "UPDATE tasks SET state='completed',result=?,previous=?,applied_revision=? WHERE id=?",
            (result, previous, revision, task),
        )
