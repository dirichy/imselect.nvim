"""One real ASCII/Chinese round trip per Linux driver, without the policy layer."""

import argparse
import json
import os
import select
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def run(*args):
    return subprocess.run(
        args, check=True, text=True, capture_output=True, timeout=15
    ).stdout.strip()


def wait(description, predicate):
    end = time.monotonic() + 15
    while time.monotonic() < end:
        result = predicate()
        if result:
            return result
        time.sleep(0.1)
    raise AssertionError(f"Timed out: {description}")


if sys.argv[1:2] != ["--session"]:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "drivers", nargs="*", choices=("fcitx", "dbus", "kitty", "neovide")
    )
    drivers = parser.parse_args().drivers or ["fcitx", "dbus", "kitty", "neovide"]
    required = (
        "Xvfb",
        "dbus-run-session",
        "fcitx5",
        "fcitx5-remote",
        "rime_deployer",
        "xdotool",
        "nvim",
        *("xterm" if name in ("fcitx", "dbus") else name for name in drivers),
    )
    missing = [name for name in required if not shutil.which(name)]
    if missing:
        sys.exit("Please install: " + ", ".join(missing))
    if not Path("/usr/share/rime-data/luna_pinyin_simp.schema.yaml").exists():
        sys.exit("Please install the Rime luna-pinyin schema data")
    output = ROOT / ".dev/native"
    output.mkdir(parents=True, exist_ok=True)
    failed = False
    for driver in drivers:
        directory = Path(tempfile.mkdtemp(prefix=driver + "-", dir=output))
        print("Native session:", directory, flush=True)
        env = os.environ.copy()
        for key in (
            "DISPLAY",
            "WAYLAND_DISPLAY",
            "SSH_TTY",
            "SSH_CONNECTION",
            "SSH_CLIENT",
            "TMUX",
        ):
            env.pop(key, None)
        for kind in ("CONFIG", "DATA", "CACHE", "STATE", "RUNTIME"):
            path = directory / kind.lower()
            path.mkdir(mode=0o700)
            env["XDG_RUNTIME_DIR" if kind == "RUNTIME" else f"XDG_{kind}_HOME"] = str(
                path
            )
        env.update(
            XMODIFIERS="@im=fcitx",
            GTK_IM_MODULE="fcitx",
            QT_IM_MODULE="fcitx",
            GLFW_IM_MODULE="ibus",
            XDG_SESSION_TYPE="x11",
            XDG_CURRENT_DESKTOP="Xvfb",
            NVIM_LOG_FILE=str(directory / "nvim.log"),
        )
        with (directory / "session.log").open("w") as log:
            result = subprocess.run(
                [
                    "dbus-run-session",
                    "--",
                    sys.executable,
                    __file__,
                    "--session",
                    str(directory),
                    driver,
                ],
                env=env,
                cwd=ROOT,
                stderr=log,
                check=False,
            )
        if result.returncode:
            failed = True
            print(
                (directory / "session.log").read_text(errors="replace")[-5000:],
                file=sys.stderr,
            )
    sys.exit(int(failed))

session = Path(sys.argv[2])
driver = sys.argv[3]
profile = Path(os.environ["XDG_CONFIG_HOME"]) / "fcitx5"
profile.mkdir()
(profile / "profile").write_text("""[Groups/0]
Name=Default
Default Layout=us
DefaultIM=rime

[Groups/0/Items/0]
Name=keyboard-us
Layout=

[Groups/0/Items/1]
Name=rime
Layout=

[GroupOrder]
0=Default
""")
rime = Path(os.environ["XDG_DATA_HOME"]) / "fcitx5/rime"
rime.mkdir(parents=True)
(rime / "default.custom.yaml").write_text(
    "patch:\n  schema_list:\n    - schema: luna_pinyin_simp\n"
)
run("rime_deployer", "--build", str(rime), "/usr/share/rime-data", str(rime / "build"))
processes, logs = [], []


def start(name, *args, **kwargs):
    log = (session / (name + ".log")).open("w")
    logs.append(log)
    process = subprocess.Popen(args, stdout=log, stderr=log, **kwargs)
    processes.append(process)
    return process


try:
    read_fd, write_fd = os.pipe()
    start(
        "xvfb",
        "Xvfb",
        "-displayfd",
        str(write_fd),
        "-screen",
        "0",
        "1024x768x24",
        "-nolisten",
        "tcp",
        pass_fds=(write_fd,),
    )
    os.close(write_fd)
    assert select.select([read_fd], [], [], 10)[0], "Xvfb did not start"
    with os.fdopen(read_fd) as pipe:
        os.environ["DISPLAY"] = ":" + pipe.readline().strip()
    run("dbus-update-activation-environment", "DISPLAY")
    start("fcitx", "fcitx5", "-D", "--ui=classicui", "--disable=wayland,waylandim")
    wait(
        "Fcitx D-Bus",
        lambda: (
            subprocess.run(
                ["fcitx5-remote", "--check"], capture_output=True, check=False
            ).returncode
            == 0
        ),
    )
    if driver in ("kitty", "neovide"):
        # These clients discover Fcitx through its normal IBus address file.
        bus_files = Path(os.environ["XDG_CONFIG_HOME"]) / "ibus/bus"
        wait(
            "IBus frontend ready",
            lambda: any(
                "IBUS_ADDRESS=unix:" in path.read_text() for path in bus_files.glob("*")
            ),
        )
    socket = str(session / (driver + ".sock"))
    nvim = ["nvim", "-n", "-i", "NONE", "-u", "NONE", "--listen", socket]
    title = "imselect-native-" + driver
    if driver == "kitty":
        command = [
            "kitty",
            "--config",
            "NONE",
            "--title",
            title,
            "-o",
            "watcher=" + str(ROOT / "examples/kitty-im-control.py"),
            *nvim,
        ]
    elif driver == "neovide":
        command = ["neovide", "--no-fork", "--", *nvim[1:]]
    else:
        command = ["xterm", "-fa", "monospace", "-title", title, "-e", *nvim]
    app = start(driver + "-app", *command)
    wait(driver + " Neovim socket", lambda: Path(socket).exists())
    windows = wait(
        driver + " window",
        lambda: subprocess.run(
            ["xdotool", "search", "--onlyvisible", "--pid", str(app.pid)],
            text=True,
            capture_output=True,
            check=False,
        ).stdout.strip(),
    )
    run("xdotool", "windowfocus", "--sync", windows.splitlines()[-1])

    def lua(code):
        expression = "luaeval('(function() " + code.replace("'", "''") + " end)()')"
        return run("nvim", "--server", socket, "--remote-expr", expression)

    lua(
        'vim.opt.rtp:prepend(vim.fn.getcwd()); _G.native_driver = require("imselect.util").with_restore(require("imselect.driver.'
        + driver
        + '").setup({})); return true'
    )
    lua('vim.cmd("startinsert"); return true')
    wait("Insert mode", lambda: lua("return vim.api.nvim_get_mode().mode") == "i")
    run("fcitx5-remote", "-s", "rime")
    run("fcitx5-remote", "-c")
    wait("inactive IME before user activation", lambda: run("fcitx5-remote") == "1")
    run("xdotool", "key", "--clearmodifiers", "ctrl+space")
    wait("active Rime after user activation", lambda: run("fcitx5-remote") == "2")
    wait(
        "Rime schema deployment",
        lambda: (rime / "build/luna_pinyin_simp.prism.bin").exists(),
    )
    run("xdotool", "type", "--clearmodifiers", "--delay", "100", "nihao ")
    try:
        wait(
            "Chinese input works before using the driver",
            lambda: (
                lua("return vim.json.encode(vim.api.nvim_get_current_line())")
                == json.dumps("你好", ensure_ascii=False)
            ),
        )
    except AssertionError:
        print(
            "Baseline text:",
            lua("return vim.json.encode(vim.api.nvim_get_current_line())"),
            file=sys.stderr,
        )
        raise
    lua('vim.api.nvim_buf_set_lines(0, 0, -1, false, {""}); return true')
    # Both calls represent repeated ASCII requirements, not a check of call counts.
    lua("native_driver.temp_ascii(); native_driver.temp_ascii(); return true")
    if driver != "neovide":
        wait("ASCII input state", lambda: run("fcitx5-remote") == "1")
    run("xdotool", "type", "--clearmodifiers", "--delay", "100", "nihao ")
    wait(
        driver + " literal ASCII input",
        lambda: (
            lua("return vim.json.encode(vim.api.nvim_get_current_line())")
            == json.dumps("nihao ")
        ),
    )
    lua(
        'vim.api.nvim_buf_set_lines(0, 0, -1, false, {""}); native_driver.restore(); return true'
    )
    if driver == "neovide":
        # Exercise the real IME connection with the user's normal activation key.
        # Reopening the gate does not promise to restore the engine's active state.
        run("xdotool", "key", "--clearmodifiers", "ctrl+space")
        wait(
            "IME activation key reaches the reopened connection",
            lambda: run("fcitx5-remote") == "2",
        )
    else:
        wait("restored Rime", lambda: run("fcitx5-remote") == "2")
    run("xdotool", "type", "--clearmodifiers", "--delay", "100", "nihao ")
    try:
        wait(
            driver + " Chinese composition",
            lambda: (
                lua("return vim.json.encode(vim.api.nvim_get_current_line())")
                == json.dumps("你好", ensure_ascii=False)
            ),
        )
    except AssertionError:
        print(
            "Observed text:",
            lua("return vim.json.encode(vim.api.nvim_get_current_line())"),
            "IME:",
            run("fcitx5-remote"),
            "engine:",
            run("fcitx5-remote", "-n"),
            file=sys.stderr,
        )
        raise
    behavior = (
        "IME input disabled / re-enabled"
        if driver == "neovide"
        else "ASCII / Chinese restoration"
    )
    print(driver + ": native " + behavior + " OK", flush=True)
    lua('vim.schedule(function() vim.cmd("qa!") end); return true')
    app.wait(timeout=10)
finally:
    for process in reversed(processes):
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
    for log in logs:
        log.close()
    (session / "result.json").write_text(
        json.dumps(
            {
                "driver": driver,
                "passed": sys.exc_info()[0] is None,
                "error": str(sys.exc_info()[1]) if sys.exc_info()[0] else None,
            }
        )
    )
    if sys.exc_info()[0]:
        for log in session.glob("*.log"):
            print(
                "\n" + log.name + "\n" + log.read_text(errors="replace")[-8000:],
                file=sys.stderr,
            )
