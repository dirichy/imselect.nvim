# Real input method demo / 真实输入法演示

Prepare the pinned color theme and LaTeX parser once, then run from the repository root:

首次准备固定版本的配色主题和 LaTeX parser，然后在项目根目录运行：

```sh
mkdir -p .dev
git clone https://github.com/folke/tokyonight.nvim .dev/tokyonight.nvim
git -C .dev/tokyonight.nvim checkout cdc07ac78467a233fd62c493de29a17e0cf2b2b6
git clone https://github.com/latex-lsp/tree-sitter-latex .dev/tree-sitter-latex
git -C .dev/tree-sitter-latex checkout fa8df448fc2c0192a8c2f8cfc97de53cb2b4ecb9
(cd .dev/tree-sitter-latex && tree-sitter generate)
mkdir -p .dev/latex/parser
cc -O2 -shared -fPIC -I .dev/tree-sitter-latex/src \
  .dev/tree-sitter-latex/src/parser.c .dev/tree-sitter-latex/src/scanner.c \
  -o .dev/latex/parser/latex.so
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
ImageMagick (`convert`) with SVG rendering support, Fontconfig, Noto Sans, and
Noto CJK fonts. The terminal uses the system monospace font; the actual selected
font is recorded in `verification.json`. Building the parser
also requires a C compiler and Tree-sitter CLI 0.26.9. The workflow installs the
pinned CLI with npm; local preparation uses your installed CLI.

依赖包括 Python 3、Neovim、Xvfb、D-Bus、xterm、xdotool、桌面版 Screenkey、带 XIM 和经典界面的
fcitx5、fcitx5-rime、Rime 朙月拼音方案数据、FFmpeg/ffprobe、支持 SVG 渲染的
ImageMagick（`convert`）、Fontconfig、Noto Sans 和 Noto CJK 字体。终端使用系统等宽字体，实际匹配结果记录在 `verification.json` 中。构建 parser
还需要 C 编译器和 Tree-sitter CLI 0.26.9；workflow 通过 npm 安装固定版本的 CLI，
本地准备使用已安装的 CLI。

For Ubuntu 24.04 package names, see
[the workflow](../.github/workflows/demo.yml). It pins Neovim to v0.12.6 with a
SHA-256 check. OS packages can receive updates, so recordings are not guaranteed
to be pixel-identical across distributions or runner-image updates.

On Ubuntu, install `librsvg2-bin` as well as `imagemagick`: ImageMagick's SVG
delegate invokes `rsvg-convert`. The script renders the window frame before
recording so a missing SVG delegate fails early; session errors are also printed
to the workflow log, with full logs retained in the debug artifact.

Ubuntu 需要同时安装 `imagemagick` 和 `librsvg2-bin`，因为 ImageMagick 的 SVG
转换会调用 `rsvg-convert`。脚本在录制前渲染窗口装饰，缺少 SVG delegate 会立即
失败；会话错误也会直接打印到 workflow 日志，完整日志仍保留在调试附件中。

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

The LaTeX sample explains both features in comments. One continuous edit starts
with `i`, commits `你好`, types `$ $`, moves Left once, types `x + y`, moves Right
once, and commits `世界`. Insert restores Chinese input; entering math selects
ASCII and returning to prose restores Chinese without leaving Insert. Escape at
the end selects ASCII. The final line is `你好$ x + y$世界`.

LaTeX 样例通过注释说明两项特性。一次连续编辑从 `i` 开始，输入 `你好`、`$ $`，
左移一次，输入 `x + y`，右移一次，再输入 `世界`。进入插入模式恢复中文，进入数学
区自动切换英文，回到正文恢复中文，全程保持插入模式；最后按 Escape 切换英文。
最终得到 `你好$ x + y$世界`。

The space in `$ $` lets the parser recognize an empty inline formula; bare `$$`
is incomplete syntax for this parser. The isolated Rime schema maps `$` directly
to the ASCII dollar instead of a currency selection menu. It still uses real
pinyin composition and commits Chinese through the input method.

`$ $` 中的空格使 parser 可以识别空的行内公式；单独 `$$` 在当前 parser 中是未完成
语法。隔离的 Rime 方案将 `$` 直接映射为美元符号，避免弹出货币符号选择菜单；
中文仍通过真实拼音组词和输入法提交。

Verification observes real Neovim events, modes, buffer contents, cursor positions,
Tree-sitter classification and fcitx states in the same session. It also asserts
that the syntax transitions do not produce any ModeChanged event. It never feeds
Chinese results directly into Neovim, replaces the driver with a mock, or toggles
the IME externally during the recorded interaction. The isolated runtime explicitly
loads the built LaTeX parser, independent of user-installed parsers and queries.

验证读取同一会话中的真实 Neovim 事件、模式、缓冲区内容、光标位置、Tree-sitter
分类和 fcitx 状态，还断言语法切换期间没有 ModeChanged 事件。不直接填入中文结果、
不替换驱动，也不在录制交互期间从外部开关输入法。隔离 runtime 显式加载上述构建的
LaTeX parser，不依赖个人安装的 parser 和 query。

Outputs are rebuilt in `demos/output/`:

产物统一生成到 `demos/output/`：

- `demo.mp4`: H.264, 1424×824, 30 fps (1280×640 desktop plus decoration).
- `demo.gif`: 1280×741, 20 fps, generated from the MP4.
- `candidates.png` / `math.png` / `restored.png` / `final.png`: key frames extracted from the same recording.
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
