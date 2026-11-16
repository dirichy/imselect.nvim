#!/usr/bin/env python3
"""Record real XIM input in an isolated Xvfb/D-Bus session."""

import json
import os
import select
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "demos/output"
OUTPUT.mkdir(parents=True, exist_ok=True)
WIDTH, HEIGHT, FPS = 1280, 640, 30
SIZE = f"{WIDTH}x{HEIGHT}"
FFMPEG = ("ffmpeg", "-y", "-loglevel", "error")
KEY_TIMEOUT = 1.5
MARGIN, PADDING, TITLEBAR, RADIUS = 56, 16, 40, 24
CARD_WIDTH = WIDTH + PADDING * 2
CARD_HEIGHT = HEIGHT + PADDING * 2 + TITLEBAR
CANVAS_WIDTH = CARD_WIDTH + MARGIN * 2
CANVAS_HEIGHT = CARD_HEIGHT + MARGIN * 2


def run(*args, check=True, timeout=15):
    result = subprocess.run(
        args, check=False, text=True, capture_output=True, timeout=timeout
    )
    if check and result.returncode:
        raise RuntimeError(f"{args!r} failed: {result.stderr}")
    return result


def wait_for(description, predicate, seconds=15):
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        value = predicate()
        if value:
            return value
        time.sleep(0.05)
    raise RuntimeError(f"Timed out waiting for {description}")


if len(sys.argv) == 1:
    required = (
        "Xvfb",
        "dbus-run-session",
        "fcitx5",
        "fcitx5-remote",
        "xterm",
        "xdotool",
        "nvim",
        "ffmpeg",
        "ffprobe",
        "fc-match",
        "screenkey",
        "convert",
    )
    missing = [tool for tool in required if not shutil.which(tool)]
    if missing:
        sys.exit("Please install: " + ", ".join(missing))
    if not Path("/usr/share/rime-data/luna_pinyin_simp.schema.yaml").is_file():
        sys.exit("Please install the Rime luna-pinyin schema data")
    if not (ROOT / ".dev/tokyonight.nvim/lua/tokyonight/init.lua").is_file():
        sys.exit(
            "Please clone folke/tokyonight.nvim into .dev/tokyonight.nvim; see demos/README.md"
        )
    (ROOT / ".dev").mkdir(exist_ok=True)
    session = Path(tempfile.mkdtemp(prefix="imselect-demo-", dir=ROOT / ".dev"))
    (OUTPUT / "verification.json").write_text(
        json.dumps({"verified": False, "session": str(session)})
    )
    env = os.environ.copy()
    for key in ("WAYLAND_DISPLAY", "SSH_TTY", "SSH_CONNECTION", "SSH_CLIENT", "TMUX"):
        env.pop(key, None)
    for kind in ("CONFIG", "DATA", "CACHE", "STATE", "RUNTIME"):
        path = session / kind.lower()
        path.mkdir(mode=0o700)
        env[f"XDG_{kind}_HOME" if kind != "RUNTIME" else "XDG_RUNTIME_DIR"] = str(path)
    env.update(
        {
            "IMSELECT_DEMO_ROOT": str(ROOT),
            "IMSELECT_DEMO_SESSION": str(session),
            "NVIM_LOG_FILE": str(session / "nvim.log"),
            "LC_ALL": "C.UTF-8",
            "XMODIFIERS": "@im=fcitx",
            "GTK_IM_MODULE": "fcitx",
            "QT_IM_MODULE": "fcitx",
            "XDG_SESSION_TYPE": "x11",
            "XDG_CURRENT_DESKTOP": "Xvfb",
            "QT_QPA_PLATFORM": "xcb",
            "GDK_BACKEND": "x11",
            "NO_AT_BRIDGE": "1",
        }
    )
    print(f"Session logs: {session}", flush=True)
    with (session / "dbus.log").open("w") as log:
        result = subprocess.run(
            [
                "dbus-run-session",
                "--",
                sys.executable,
                __file__,
                "--session",
                str(session),
            ],
            check=False,
            env=env,
            cwd=ROOT,
            stderr=log,
        )
    if result.returncode:
        print(
            f"Recording failed; inspect {OUTPUT / 'verification.json'} and {session}",
            file=sys.stderr,
        )
    sys.exit(result.returncode)

session = Path(sys.argv[2])
config = session / "config/fcitx5"
config.mkdir()
(config / "conf").mkdir()
(config / "conf/classicui.conf").write_text(
    'Font="Noto Sans CJK SC 18"\nMenuFont="Noto Sans CJK SC 18"\n'
)
(config / "profile").write_text("""[Groups/0]
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
rime = session / "data/fcitx5/rime"
rime.mkdir(parents=True)
(rime / "default.custom.yaml").write_text(
    "patch:\n  schema_list:\n    - schema: luna_pinyin_simp\n"
)
socket = session / "nvim.sock"
processes = []
logs = []
evidence = {"verified": False, "session": str(session), "phases": []}
evidence["versions"] = {
    "neovim": run("nvim", "--version").stdout.splitlines()[0],
    "fcitx": run("fcitx5", "--version").stdout.strip(),
    "screenkey": run("screenkey", "--version").stdout.strip(),
    "font": run("fc-match", "-f", "%{family}: %{file}", "monospace").stdout,
}
verification = OUTPUT / "verification.json"
verification.write_text(json.dumps(evidence, indent=2))
record_started = None


def start(name, *args, **kwargs):
    log = (session / f"{name}.log").open("w")
    logs.append(log)
    process = subprocess.Popen(args, stdout=log, stderr=log, **kwargs)
    processes.append(process)
    return process


def snapshot():
    return json.loads(
        run(
            "nvim",
            "--server",
            str(socket),
            "--remote-expr",
            'luaeval("vim.json.encode(imselect_demo_snapshot())")',
        ).stdout
    )


def phase(name, mode, state, text):
    def matches():
        current = snapshot()
        active = run("fcitx5-remote").stdout.strip()
        if current["mode"] == mode and active == state and current["lines"][3] == text:
            assert not current["error"], current["error"]
            return {
                "name": name,
                "ime": active,
                "editor": current,
                "seconds": time.monotonic() - record_started if record_started else 0,
            }

    evidence["phases"].append(wait_for(name, matches))


def capture(name, seconds):
    run(
        *FFMPEG,
        "-ss",
        str(seconds),
        "-i",
        str(OUTPUT / "demo.mp4"),
        "-frames:v",
        "1",
        "-threads",
        "1",
        str(OUTPUT / name),
    )


try:
    read_fd, write_fd = os.pipe()
    start(
        "xvfb",
        "Xvfb",
        "-displayfd",
        str(write_fd),
        "-screen",
        "0",
        f"{SIZE}x24",
        "-nolisten",
        "tcp",
        pass_fds=(write_fd,),
    )
    os.close(write_fd)
    assert select.select([read_fd], [], [], 10)[0], "Xvfb did not choose a display"
    with os.fdopen(read_fd) as pipe:
        os.environ["DISPLAY"] = ":" + pipe.readline().strip()
    start("fcitx", "fcitx5", "-D", "--ui=classicui", "--disable=wayland,waylandim")
    wait_for(
        "fcitx D-Bus",
        lambda: run("fcitx5-remote", "--check", check=False).returncode == 0,
    )
    start(
        "xterm",
        "xterm",
        "-title",
        "imselect-demo",
        "-fa",
        "monospace",
        "-fs",
        "20",
        "-geometry",
        "80x24+0+0",
        "-bw",
        "0",
        "-b",
        "0",
        "-bg",
        "#1a1b26",
        "-fg",
        "#c0caf5",
        "-xrm",
        "XTerm*inputMethod: fcitx",
        "-e",
        "nvim",
        "-n",
        "-i",
        "NONE",
        "-u",
        str(ROOT / "demos/init.lua"),
        "--listen",
        str(socket),
    )
    window = wait_for(
        "xterm window",
        lambda: run(
            "xdotool",
            "search",
            "--onlyvisible",
            "--name",
            "^imselect-demo$",
            check=False,
        ).stdout.strip(),
    )
    run("xdotool", "windowsize", "--sync", window, str(WIDTH), str(HEIGHT))
    run("xdotool", "windowfocus", "--sync", window)
    run("fcitx5-remote", "-s", "rime")
    run("fcitx5-remote", "-o")
    wait_for(
        "active Rime",
        lambda: (
            run("fcitx5-remote").stdout.strip() == "2"
            and run("fcitx5-remote", "-n").stdout.strip() == "rime"
        ),
    )
    (session / "start").touch()
    wait_for("Neovim initialization", lambda: (session / "ready").exists())
    phase("initial normal", "n", "1", "")

    screenkey = start(
        "screenkey",
        "screenkey",
        "--no-systray",
        "--persist",
        "--position",
        "fixed",
        "--geometry",
        f"480x64+{(WIDTH - 480) // 2}+{HEIGHT - 170}",
        "--key-mode",
        "translated",
        "--timeout",
        str(KEY_TIMEOUT),
        "--font",
        "Sans Bold",
        "--font-color",
        "#c0caf5",
        "--bg-color",
        "#24283b",
        "--opacity",
        "1",
    )
    evidence["screenkey_window"] = wait_for(
        "Screenkey overlay",
        lambda: run(
            "xdotool",
            "search",
            "--onlyvisible",
            "--pid",
            str(screenkey.pid),
            check=False,
        ).stdout.strip(),
    )

    recorder = start(
        "ffmpeg",
        *FFMPEG,
        "-f",
        "x11grab",
        "-draw_mouse",
        "0",
        "-framerate",
        str(FPS),
        "-video_size",
        SIZE,
        "-i",
        os.environ["DISPLAY"],
        "-an",
        "-c:v",
        "libx264",
        "-preset",
        "veryfast",
        "-crf",
        "18",
        "-pix_fmt",
        "yuv420p",
        "-movflags",
        "+faststart",
        str(session / "raw.mp4"),
        stdin=subprocess.PIPE,
    )
    record_started = time.monotonic()
    time.sleep(1)
    run("xdotool", "key", "--clearmodifiers", "i")
    phase("insert restores IME", "i", "2", "")
    # Separate action groups in the key overlay; state synchronization uses phase().
    time.sleep(KEY_TIMEOUT + 0.2)
    run("xdotool", "type", "--clearmodifiers", "--delay", "160", "nihao")
    time.sleep(1)
    phase("uncommitted pinyin", "i", "2", "")
    time.sleep(0.5)
    run("xdotool", "key", "space")
    phase("Chinese committed", "i", "2", "你好")
    time.sleep(KEY_TIMEOUT + 0.2)
    run("xdotool", "key", "Escape")
    phase("Escape selects ASCII", "n", "1", "你好")
    time.sleep(KEY_TIMEOUT + 0.2)
    run("xdotool", "key", "0", "l")
    assert snapshot()["cursor"] == [4, 3], (
        "normal commands must move across Chinese text"
    )
    time.sleep(KEY_TIMEOUT + 0.2)
    run("xdotool", "key", "A")
    phase("insert restores IME again", "i", "2", "你好")
    time.sleep(KEY_TIMEOUT + 0.2)
    run("xdotool", "type", "--clearmodifiers", "--delay", "160", "shijie")
    time.sleep(1)
    run("xdotool", "key", "space")
    phase("Chinese committed again", "i", "2", "你好世界")
    time.sleep(KEY_TIMEOUT + 0.2)
    run("xdotool", "key", "Escape")
    phase("final normal", "n", "1", "你好世界")
    assert screenkey.poll() is None, "Screenkey stopped during recording"
    time.sleep(2)
    recorder.communicate(b"q\n", timeout=10)
    assert recorder.returncode == 0, "recording failed"
    # Decorate the full desktop capture without cropping candidate windows or keys.
    frame = session / "frame.svg"
    frame.write_text(f'''<svg xmlns="http://www.w3.org/2000/svg"
        width="{CANVAS_WIDTH}" height="{CANVAS_HEIGHT}">
      <rect x="{MARGIN}" y="{MARGIN + 10}" width="{CARD_WIDTH}"
        height="{CARD_HEIGHT}" rx="{RADIUS}" fill="#000000" opacity="0.24"/>
      <rect x="{MARGIN}" y="{MARGIN}" width="{CARD_WIDTH}"
        height="{CARD_HEIGHT}" rx="{RADIUS}" fill="#1a1b26"
        stroke="#414868" stroke-width="1"/>
      <circle cx="{MARGIN + 24}" cy="{MARGIN + TITLEBAR // 2}" r="6" fill="#ff5f57"/>
      <circle cx="{MARGIN + 44}" cy="{MARGIN + TITLEBAR // 2}" r="6" fill="#ffbd2e"/>
      <circle cx="{MARGIN + 64}" cy="{MARGIN + TITLEBAR // 2}" r="6" fill="#28c840"/>
      <text x="{CANVAS_WIDTH // 2}" y="{MARGIN + 26}" text-anchor="middle"
        font-family="Noto Sans" font-size="15" fill="#a9b1d6">imselect.nvim · Neovim</text>
    </svg>''')
    run("convert", "-background", "none", str(frame), str(session / "frame.png"))
    run(
        *FFMPEG,
        "-i",
        str(session / "raw.mp4"),
        "-loop",
        "1",
        "-framerate",
        str(FPS),
        "-i",
        str(ROOT / "demos/backdrop.png"),
        "-loop",
        "1",
        "-framerate",
        str(FPS),
        "-i",
        str(session / "frame.png"),
        "-filter_complex",
        f"[1:v]scale={CANVAS_WIDTH}:{CANVAS_HEIGHT}[bg];"
        "[bg][2:v]overlay=0:0:shortest=1[frame];"
        f"[frame][0:v]overlay={MARGIN + PADDING}:{MARGIN + TITLEBAR + PADDING}:shortest=1,format=yuv420p[out]",
        "-map",
        "[out]",
        "-an",
        "-c:v",
        "libx264",
        "-preset",
        "veryfast",
        "-crf",
        "18",
        "-movflags",
        "+faststart",
        str(OUTPUT / "demo.mp4"),
        timeout=90,
    )
    evidence["media"] = json.loads(
        run(
            "ffprobe",
            "-v",
            "error",
            "-show_entries",
            "stream=codec_name,width,height,r_frame_rate:format=duration,size",
            "-of",
            "json",
            str(OUTPUT / "demo.mp4"),
        ).stdout
    )
    stream = evidence["media"]["streams"][0]
    assert (
        stream["codec_name"],
        stream["width"],
        stream["height"],
        stream["r_frame_rate"],
    ) == ("h264", CANVAS_WIDTH, CANVAS_HEIGHT, f"{FPS}/1"), (
        f"Unexpected video stream: {stream}"
    )
    assert float(evidence["media"]["format"]["duration"]) > 5, "Recording is too short"
    for name, marker in (
        ("candidates.png", "uncommitted pinyin"),
        ("final.png", "final normal"),
    ):
        capture(
            name,
            next(
                item["seconds"] for item in evidence["phases"] if item["name"] == marker
            )
            + (1.0 if marker == "final normal" else 0.2),
        )
    filters = "fps=20,scale=1280:-1:flags=lanczos"
    palette = str(session / "palette.png")
    video = str(OUTPUT / "demo.mp4")
    run(
        *FFMPEG,
        "-i",
        video,
        "-vf",
        filters + ",palettegen=stats_mode=diff",
        "-frames:v",
        "1",
        "-threads",
        "1",
        palette,
        timeout=90,
    )
    run(
        *FFMPEG,
        "-i",
        video,
        "-i",
        palette,
        "-filter_complex",
        filters
        + "[video];[video][1:v]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle",
        "-loop",
        "0",
        str(OUTPUT / "demo.gif"),
        timeout=90,
    )
    (OUTPUT / "README.local.md").write_text(
        "# imselect.nvim demo\n\n![Demo](demo.gif)\n\n[MP4](demo.mp4) · [Verification](verification.json)\n"
    )
    evidence["verified"] = True
except Exception as error:
    evidence["error"] = str(error)
    raise
finally:
    verification.write_text(json.dumps(evidence, ensure_ascii=False, indent=2))
    try:
        run("fcitx5-remote", "--check", "-e", check=False)
    except (OSError, subprocess.TimeoutExpired):
        pass  # The process cleanup below also handles an unresponsive daemon.
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
print(f"Verified recording: {OUTPUT / 'demo.mp4'}")
