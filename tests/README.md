# Tests / 测试

## Regression / 普通回归

```sh
for test in tests/*.lua; do
  nvim --headless -u NONE -i NONE -l "$test" || exit 1
done
```

Run from the repository root. Neovim processes actual input and parses real syntax;
editing-policy tests use `support/driver.lua`, not a platform driver. No system IME
is changed. `syntax_latex.lua` needs a LaTeX parser; CI builds the pinned grammar.

在项目根目录运行。Neovim 处理真实按键、模式事件和语法树；编辑策略使用
`support/driver.lua` 中的模拟 driver，不依赖任何平台驱动，也不切换系统输入法。
`syntax_latex.lua` 需要 LaTeX parser，CI 会构建固定版本。

Each retained file has a distinct reason / 每个文件保留的理由：

| Test | User scenario / 使用场景 |
| --- | --- |
| `modes.lua` | Insert, completion, search and Ex commands use the right policy / 插入、补全、搜索和 Ex 命令的策略不同 |
| `syntax_switch.lua` | Moving/editing across text and code, including manual IME choices / 跨语法边界移动或编辑，以及手动选择输入法 |
| `syntax.lua` | Quotes, interpolation, injections and incomplete code / 引号、插值、注入语言和未完成代码的边界 |
| `syntax_latex.lua` | Prose, formulas and text within formulas / 正文、公式和公式内文本 |
| `buffer_switch.lua` | Switching buffers/filetypes updates input and preserves buffer overrides / 切换 buffer 或 filetype 更新输入法，保留 buffer 覆盖 |
| `restore.lua` | Repeated ASCII requests, manual changes and retry after a failed restore / 重复请求、手动选择及恢复失败重试 |
| `driver_selection.lua` | Selecting a usable driver and respecting user overrides / 选择可用驱动并尊重用户配置 |
| `inspector.lua` | Scoped overrides, removal and buffer closure collection / 三层覆盖、移除和 buffer 闭包回收 |
| `run.lua` | External commands fail, time out or finish asynchronously / 外部命令失败、超时和异步完成 |

Removed adapter mocks that repeated command arguments, private protocol details,
query counts and shared restoration tests. Driver selection still stubs the OS and
executable availability because it tests environment selection, not native support.

已移除重复验证驱动参数、私有通信协议、查询次数和公共恢复逻辑的 adapter mock。
驱动选择仍模拟操作系统和可执行文件是否存在：它验证选择规则，不证明平台支持。

## Native drivers / 原生驱动

[Tests CI](../.github/workflows/test.yml) separates native jobs from regression.
Native tests call the driver directly, without mode or syntax policies. Each driver
gets one round trip appropriate to its contract: state-based drivers switch to ASCII
and restore; Neovide disables and re-enables IME input.
Actual state comes from an OS observer. Neovide additionally checks literal input
and Chinese composition because its contract is an IME input gate. Loading a module or exiting successfully is not enough.

CI 将原生驱动与普通回归分开运行。原生测试直接调用 driver，不加载模式或语法策略。
每个驱动只测一条符合自身职责的主流程：状态型驱动切英文并恢复；Neovide 禁止并重新允许
IME 输入。由系统观察器读取实际状态；Neovide 额外验证英文直输和中文组词，因为它负责 IME 输入开关。
仅加载模块或命令退出成功不算通过。

| Driver | Native environment / 原生环境 | Entry / 入口 |
| --- | --- | --- |
| `fcitx` | Fcitx5 + Rime + xterm | `python3 tests/native/linux.py fcitx` |
| `fcitx_dbus` | Fcitx5 + Rime + xterm + libdbus-1 | `python3 tests/native/linux.py fcitx_dbus` |
| `kitty` | Kitty + the documented watcher + Fcitx5 / 文档中的 watcher | `python3 tests/native/linux.py kitty` |
| `neovide` | Actual Neovide + Fcitx5 / 真实 Neovide | `python3 tests/native/linux.py neovide` |
| `macism` | macOS built-in ABC/Pinyin + macism / 系统 ABC 与拼音 | `tests/native/state.lua`, `macos-control.swift` |
| `im_select` | Windows console + US/Chinese keyboards + upstream executable / 真实控制台与上游程序 | `./tests/native/windows.ps1 im_select` |
| `winime` | Windows console + Chinese IME / 真实控制台与中文输入法 | `./tests/native/windows.ps1 winime` |
| `wsl` | Ubuntu under WSL1 + Windows console + system PowerShell / WSL1 Ubuntu 与系统 PowerShell | `./tests/native/windows.ps1 wsl` |

Neovide's native test checks the IME input path: first Chinese composition works,
then disabling the gate gives literal ASCII, and after reopening the user's normal
Ctrl+Space activation key reaches the IME and Chinese commits reach Neovim again.
It never changes Fcitx state to make the final assertion pass. This distinguishes a
working IME connection from merely assigning `neovide_input_ime`.

Neovide 原生测试验证输入链路：先确认中文组词可用，关闭后英文直输；重新允许后，
用户正常的 Ctrl+Space 激活键能到达输入法，中文提交能再次进入 Neovim。
最后一步不通过外部命令改 Fcitx 状态来达成，验证的也不只是变量赋值。

Linux runs an isolated Xvfb/D-Bus desktop with a normal Rime profile, deployed before
input begins. It does not modify the current desktop. Windows/macOS tests change the
foreground input method: run them in a dedicated test session. Install dependencies
first; scripts never patch drivers, replace IME windows or silently skip missing tools.
The workflow logs/reports expose unavailable prerequisites as failures.

Linux 使用隔离的 Xvfb/D-Bus 桌面和普通 Rime 配置，在输入前部署词库，不修改当前桌面。
Windows/macOS 测试会改变前台输入法，应在专用测试会话运行。请先安装依赖；脚本不修改驱动、
不伪造 IME 窗口，也不静默跳过缺失工具。缺少运行条件会明确失败并保留日志或报告。

### Fcitx5 macOS (manual / 手动)

Select and activate Fcitx5 first, then run on a macOS desktop:
先在 macOS 桌面选中并启用 Fcitx5，然后运行：

```sh
nvim --headless -u NONE -i NONE -l tests/native/fcitx_macos_direct.lua
```

This changes the selected input source and restores it on completion. It compares
native driver state with the upstream CLI, checks repeated ASCII requests and
restoration, and verifies that selecting the system ABC source reports inactive.
It needs the Fcitx5 app and an enabled ABC source. This is a state test, not a test
of literal Chinese composition. It has not yet been run on macOS and is not part
of hosted CI, which only has built-in input methods configured.

此测试会切换系统输入源，并在结束时恢复。使用上游 CLI 对照原生驱动状态，
验证重复 ASCII 请求、恢复和切到系统 ABC 后的状态。需要安装 Fcitx5 并启用 ABC。
它验证状态，不证明真实中文组词可用。尚未在 macOS 实机执行；托管 CI 仅配置了
系统输入法，因此不将此项加入 CI。

Coverage limits / 覆盖边界：

- WSL1 exercises actual Windows interop. WSL2 is not inferred from it; hosted-runner
  nested virtualization is not guaranteed. / WSL1 验证真实 Windows 互操作；WSL2
  依赖托管机不保证提供的嵌套虚拟化，不能据此宣称已覆盖。
- Linux covers Fcitx5/X11. Fcitx4, Wayland and macOS Fcitx need their own environments.
  / Linux 覆盖 Fcitx5/X11；Fcitx4、Wayland 和 macOS Fcitx 仍需对应环境。
- Kitty's local watcher is covered; tmux/SSH transport needs a separate client/server
  setup. / Kitty 覆盖本地 watcher，tmux/SSH 完整链路需要额外客户端与服务器环境。
- Windows tests use the console provided by the OS, not every Windows Terminal,
  third-party IME or frontend version. A runner without an interactive foreground
  window cannot establish switching support. / Windows 使用系统控制台，不穷举 Windows
  Terminal、第三方输入法及前端版本；缺少交互桌面的 runner 不能证明切换可用。

The existing [Demos CI](../.github/workflows/demo.yml) remains a Linux end-to-end
check of editing policies together with the real fcitx driver.

现有 Demos CI 继续验证 Linux 上编辑策略与真实 fcitx driver 的完整链路。

Verified runs / 已验证记录：

- [Development-branch CI](https://github.com/dirichy/imselect.nvim/actions/runs/46137679719)
  passed regression and all eight configured native jobs: fcitx, D-Bus, Kitty,
  Neovide, macism, im-select, winime and WSL1.
  / 开发分支 CI 已通过普通回归及配置的八项原生测试：fcitx、D-Bus、Kitty、Neovide、
  macism、im-select、winime 和 WSL1。
- Local Linux checks also passed input-state round trips for fcitx, D-Bus and Kitty,
  and actual IME gating/composition in Neovide 0.17.4 with Fcitx5 5.1.23.
  / 本地 Linux 也已通过 fcitx、D-Bus、Kitty 的状态切换与恢复，以及 Neovide 0.17.4
  配合 Fcitx5 5.1.23 的 IME 开关和中文提交。
- `fcitx_macos_direct` still requires its separate manual macOS test described above.
  / `fcitx_macos_direct` 仍需执行上面的 macOS 手动测试，尚无实测通过记录。

Kitty uses `GLFW_IM_MODULE=ibus` as required by the [Fcitx setup guide](https://fcitx-im.org/wiki/Setup_Fcitx_5/en); the fixture waits for its IBus frontend before launching clients. / Kitty 按 Fcitx 官方说明使用 IBus，测试先等待正常前端就绪，再启动客户端。
