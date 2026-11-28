"""Verify the packaged GNOME launcher under a disposable fractional-scale parent."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
from contextlib import ExitStack


def wait_for(check):
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        value = check()
        if value:
            return value
        time.sleep(0.05)
    raise TimeoutError(f"Waiting for {check}")


def start(stack, command, env):
    process = subprocess.Popen(command, env=env)

    def close():
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=4)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()

    stack.callback(close)
    return process


def find_window(node, app_id):
    if node.get("app_id") == app_id:
        return node
    for child in node["nodes"] + node["floating_nodes"]:
        result = find_window(child, app_id)
        if result:
            return result


def check_launcher(package):
    launcher = package / "bin/spaces-session"
    with (
        tempfile.TemporaryDirectory(prefix="spaces-launch-") as folder,
        ExitStack() as stack,
    ):
        root = Path(folder)
        runtime = root / "run"
        runtime.mkdir(mode=0o700)
        config = root / "sway.conf"
        config.write_text(
            "output * mode 1920x1200 scale 1.5\nseat seat0 fallback true\n"
        )
        env = os.environ.copy()
        for key in (
            "WAYLAND_DISPLAY",
            "DISPLAY",
            "SWAYSOCK",
            "I3SOCK",
            "XDG_ACTIVATION_TOKEN",
        ):
            env.pop(key, None)
        env.update(
            HOME=folder,
            XDG_RUNTIME_DIR=str(runtime),
            XDG_CURRENT_DESKTOP="sway",
            XDG_STATE_HOME=str(root / "state"),
            XDG_CONFIG_HOME=str(root / "config"),
            XDG_DATA_HOME=str(root / "data"),
            XDG_CACHE_HOME=str(root / "cache"),
            WLR_BACKENDS="headless",
            WLR_RENDERER="pixman",
            WLR_LIBINPUT_NO_DEVICES="1",
        )
        start(stack, ["sway", "-c", config], env)
        env["WAYLAND_DISPLAY"] = wait_for(
            lambda: next(
                (p.name for p in runtime.glob("wayland-*") if p.is_socket()), None
            )
        )
        env["SWAYSOCK"] = str(
            wait_for(lambda: next(runtime.glob("sway-ipc*.sock"), None))
        )

        def message(*args):
            return json.loads(
                subprocess.check_output(["swaymsg", "-r", *args], env=env)
            )

        def window(identity):
            return wait_for(lambda: find_window(message("-t", "get_tree"), identity))

        def close_window(surface, process):
            message(f"[con_id={surface['id']}] kill")
            assert process.wait(timeout=10) == 0

        primary = "org.spacesos.Spaces"
        session = start(stack, [launcher, "nested"], env)
        outer = window(primary)
        assert outer["fullscreen_mode"] and (
            outer["rect"]["width"],
            outer["rect"]["height"],
        ) == (1280, 800)
        display = wait_for(
            lambda: next(runtime.glob("spaces-nested/run-*/runtime/wayland-0"), None)
        )
        nested_env = env | {
            "XDG_RUNTIME_DIR": str(display.parent),
            "WAYLAND_DISPLAY": display.name,
        }

        def correctly_scaled():
            info = subprocess.check_output(["wayland-info"], env=nested_env, text=True)
            return (
                "logical_width: 1280, logical_height: 800" in info
                and "width: 1920 px, height: 1200 px" in info
            )

        wait_for(correctly_scaled)
        activity = Path(".local/state/SpacesOS/arlo/activity.sqlite")
        saved = root / "state/SpacesOS/nested" / activity
        wait_for(saved.is_file)
        subprocess.run([launcher, "nested"], env=env, check=True, timeout=5)
        assert window(primary)["id"] == outer["id"]

        disposable = start(stack, [launcher, "nested", "--disposable"], env)
        test_window = window("org.spacesos.Test")
        temporary = wait_for(
            lambda: next(runtime.glob(f"spaces-test-*/home/{activity}"), None)
        )
        assert not temporary.samefile(saved)
        close_window(test_window, disposable)
        assert not temporary.exists() and window(primary)["id"] == outer["id"]
        close_window(outer, session)
        assert not display.parent.exists() and saved.exists()

        reopened = start(stack, [launcher, "nested"], env)
        next_window = window(primary)
        assert next_window["id"] != outer["id"]
        close_window(next_window, reopened)


if __name__ == "__main__":
    check_launcher(Path(sys.argv[1]).resolve(strict=True))
    print("Passed fullscreen geometry, reuse, profile separation, close and reopen.")
