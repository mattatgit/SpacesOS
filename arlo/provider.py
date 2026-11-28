"""A local, inference-only adapter. The model can propose one data operation."""

import json
import os
import subprocess
import tempfile
import time

SYSTEM = """Translate the last user message into one dock-height operation.
Use unsupported for other topics, applications, commands or ambiguous requests.
Use read only for a question about the dock height. Use set with the exact requested
height for a resize or correction. Use undo for reversing the last change.
Reply only with the JSON operation. Never claim a change has been made."""

EXAMPLES = [
    ("Open a terminal", {"op": "unsupported"}),
    ("Make the dock 80 pixels high", {"op": "set", "height": 80}),
    ("Actually, use 64", {"op": "set", "height": 64}),
    ("What size is it now?", {"op": "read"}),
    ("Undo that", {"op": "undo"}),
    ("Show my files", {"op": "unsupported"}),
]


def propose(request, height, history, cancelled):
    # Raw user text cannot inject a chat-template delimiter.
    def turn(role, content):
        return f"<|im_start|>{role}\n" + content.replace("<|", "‹|") + "<|im_end|>\n"

    context = json.dumps(history, ensure_ascii=False)
    prompt = turn(
        "system",
        f"{SYSTEM}\nCurrent dock height: {height} px. Prior activity: {context}",
    )
    for example, operation in EXAMPLES:
        prompt += turn("user", example) + turn("assistant", json.dumps(operation))
    prompt += turn("user", request) + "<|im_start|>assistant\n"
    with tempfile.TemporaryFile() as input_file:
        input_file.write(prompt.encode())
        input_file.seek(0)
        try:
            process = subprocess.Popen(
                ["spaces-arlo-infer"],
                stdin=input_file,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                env={"PATH": os.environ["PATH"], "LC_ALL": "C.UTF-8"},
            )
        except OSError as exc:
            raise ValueError(
                "The local model is unavailable. Check the Spaces package and retry."
            ) from exc
        try:
            deadline = time.monotonic() + 50
            while True:
                if cancelled.is_set():
                    raise ValueError("Cancelled.")
                if time.monotonic() >= deadline:
                    raise ValueError("The local model timed out. Retry the request.")
                try:
                    output, _ = process.communicate(timeout=0.15)
                    break
                except subprocess.TimeoutExpired:
                    pass
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
        if process.returncode:
            raise ValueError("Local inference failed. Retry the request.")
        try:
            return json.loads(
                output.decode().strip().removesuffix("[end of text]").strip()
            )
        except (ValueError, UnicodeError) as exc:
            raise ValueError(
                "The model returned an unreadable operation. Retry or rephrase."
            ) from exc
