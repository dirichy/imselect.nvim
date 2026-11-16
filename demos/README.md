# Real input method demo / 真实输入法演示

Prepare the pinned color theme once, then run from the repository root:

首次准备固定版本的配色主题，然后在项目根目录运行：

```sh
mkdir -p .dev
git clone https://github.com/folke/tokyonight.nvim .dev/tokyonight.nvim
git -C .dev/tokyonight.nvim checkout cdc07ac78467a233fd62c493de29a17e0cf2b2b6
python3 demos/record.py
```

The script starts its own Xvfb and D-Bus session with isolated XDG directories.
It uses xterm's XIM support, fcitx5-rime with the `luna_pinyin_simp` schema, and
XTEST key events from xdotool. Desktop Screenkey shows actual keys, and the sample
text explains each operation. It works without a physical display and does not
use or edit the current desktop's input method configuration. It never installs
software. Install missing dependencies yourself when prompted.

脚本启动独立的 Xvfb、D-Bus 会话和 XDG 目录，通过 xterm 的 XIM、fcitx5-rime 的
`luna_pinyin_simp` 方案，以及 xdotool 的 XTEST 按键事件完成录制。桌面版 Screenkey
显示真实按键，演示文本本身解释各步操作。无需物理显示器，
不使用或修改当前桌面的输入法配置。脚本不会安装软件；缺少依赖时请自行安装。

Dependencies: Python 3, Neovim, Xvfb, D-Bus, xterm, xdotool, desktop Screenkey, fcitx5 with XIM and
classic UI modules, fcitx5-rime, Rime luna-pinyin schema data, FFmpeg/ffprobe,
ImageMagick (`convert`), Fontconfig, Noto Sans, and Noto CJK fonts. The terminal uses the system monospace font;
the actual selected font is recorded in `verification.json`.

依赖包括 Python 3、Neovim、Xvfb、D-Bus、xterm、xdotool、桌面版 Screenkey、带 XIM 和经典界面的
fcitx5、fcitx5-rime、Rime 朙月拼音方案数据、FFmpeg/ffprobe、ImageMagick（`convert`）、Fontconfig、Noto Sans 和 Noto CJK
字体。终端使用系统等宽字体，实际匹配结果记录在 `verification.json` 中。

For Ubuntu 24.04 package names, see
[the workflow](../.github/workflows/demo.yml). It pins Neovim to v0.12.6 with a
SHA-256 check. OS packages can receive updates, so recordings are not guaranteed
to be pixel-identical across distributions or runner-image updates.

Ubuntu 24.04 的包名见上述 workflow。Neovim 固定为 v0.12.6 并校验 SHA-256；系统包
仍会更新，因此不同发行版或 runner 镜像更新后的画面不保证逐像素一致。

The editor uses TokyoNight Night. After capture, FFmpeg adds a rounded window,
colored title-bar buttons, padding, and the same gradient background used by the
VHS demos. The entire desktop frame is retained, including the real candidate
popup and desktop Screenkey. Decoration does not change the observed interaction.
The background is copied from
[flash-any.nvim](https://github.com/dirichy/flash-any.nvim/tree/433b7fe3c197e757492f3015693bbf7096423939/demos/common),
with its [MIT license](backdrop.LICENSE).

编辑器使用 TokyoNight Night；录制后通过 FFmpeg 合成圆角窗口、彩色标题栏按钮、
内边距，以及之前 VHS 使用的渐变背景。完整保留原始桌面画面，包括真实候选框和
桌面 Screenkey；装饰不改变交互验证。背景沿用上述 flash-any.nvim 素材，保留 MIT 许可证。

The recording verifies normal-mode ASCII, IME restoration on Insert, uncommitted
pinyin followed by committed Chinese, Escape back to ASCII, normal cursor
movement, and a second insertion that produces `你好世界`. It observes real Neovim
events, modes, buffer contents, cursor positions, and fcitx states. It never feeds
Chinese text directly into Neovim or replaces the driver with a mock.

录制验证普通模式英文输入、插入模式恢复输入法、拼音组词后提交中文、Escape 回到
英文、普通模式光标移动，以及再次插入得到 `你好世界`。验证读取真实 Neovim 事件、
模式、缓冲区内容、光标位置和 fcitx 状态，不直接向 Neovim 填入结果，也不替换驱动。

Outputs are rebuilt in `demos/output/`:

产物统一生成到 `demos/output/`：

- `demo.mp4`: H.264, 1424×824, 30 fps (1280×640 desktop plus decoration).
- `demo.gif`: 1280×741, 20 fps, generated from the MP4.
- `candidates.png` / `final.png`: key frames extracted from the same recording.
- `verification.json`: phase observations, versions, media properties, and
  `verified: true` only after all checks and conversions succeed.
- `README.local.md`: local preview links / 本地预览链接。

Failure evidence and temporary state remain under `.dev/imselect-demo-*/` for
inspection. Child processes are stopped after each run. The workflow uploads
verified results as a short-lived artifact, and uploads logs separately on
failure.

失败证据和临时状态保留在 `.dev/imselect-demo-*/`，便于检查；每轮结束会停止子进程。
工作流成功后上传短期 artifact，失败时单独上传日志。

## Release media / Release 媒体

The workflow records on every push to `main` and on manual dispatch.
Successful runs on the default branch publish `demo.gif`, `demo.mp4`, and
`verification.json` to the dedicated `demos` prerelease, replacing assets with
the same names. Only the publish job has `contents: write`; workflow runs are
serialized per branch to avoid overlapping uploads or older recordings replacing
newer ones.

工作流在每次向 `main` 推送或手动触发时录制；默认分支上成功的运行将 GIF、MP4
和验证记录发布到独立的 `demos` 预发布 Release，覆盖同名附件。
仅发布 job 拥有 `contents: write`；同一分支的工作流串行执行，避免并行覆盖或旧录制
覆盖新录制。

The root README embeds fixed URLs under
`https://github.com/dirichy/imselect.nvim/releases/download/demos/`, so new
recordings do not require another README edit. This prerelease is not marked as
the latest plugin release.

项目 README 使用上述固定附件地址；重录后无需再次修改 README。此预发布 Release
不会被标记为最新插件版本。

Recording stays local. After the workflow is committed and pushed, Actions owns
publication: it checks `verified: true` and nonempty assets before creating or
updating the Release, then checks both README media URLs. The fixed URLs become
available after the first successful publication.

本地录制只生成本地产物。工作流提交并推送后，由 Actions 负责发布：先检查验证通过
且附件非空，再创建或更新 Release，最后检查 README 的 GIF、MP4 地址。首次成功
发布后，固定地址才会可用。

Local Arch Linux verification has passed. The workflow is prepared for a hosted
Ubuntu runner; a successful local recording does not establish that it has
already passed on GitHub Actions.

本地 Arch Linux 验证已通过；工作流已为托管 Ubuntu runner 准备好。本地录制成功
不代表已经在 GitHub Actions 上实际运行通过。
