This plugin is to switch im autometically in neovim. 

## Demo / 演示

![Automatic input method switching](https://github.com/dirichy/imselect.nvim/releases/download/demos/demo.gif)

Real fcitx5-rime input: Insert restores Chinese input; Escape switches to ASCII.
真实 fcitx5-rime 输入：进入插入模式恢复中文输入，Escape 切换至英文。

[HD video / 高清视频](https://github.com/dirichy/imselect.nvim/releases/download/demos/demo.mp4)
· [Recording instructions / 录制说明](demos/README.md)

# features
## force ascii mode in normal mode
## multi driver.
including fcitx, macism, neovide. and user can provide thier own driver, too. 

Drivers are selected once during `setup()`, in this order:

1. Neovide always uses the `neovide` driver, regardless of SSH environment variables.
2. Other SSH sessions use `default_driver.ssh` (default: `"kitty"`). Setting
   `enable_in_ssh = false` disables imselect in these sessions only.
3. Other sessions use `default_driver[os]`, where `os` is `Linux`, `Darwin`, `Windows_NT`, etc.

驱动在 `setup()` 时按以下顺序选择一次：

1. Neovide 始终使用 `neovide` 驱动，不受 SSH 环境变量影响。
2. 其他 SSH 会话使用 `default_driver.ssh`，默认为 `"kitty"`。
   `enable_in_ssh = false` 只在这些会话中禁用 imselect。
3. 其余会话使用 `default_driver[os]`，其中 `os` 为 `Linux`、`Darwin`、`Windows_NT` 等系统名。

```lua
require("imselect").setup({
  default_driver = { Linux = "fcitx", Darwin = "fcitx", ssh = "kitty" },
  enable_in_ssh = true,
})
```

### Windows

Windows terminal sessions default to the `im_select` driver. Install
[`im-select.exe`](https://github.com/daipeihust/im-select) and put it on `PATH`,
or configure its full path. The default ASCII layout ID is `"1033"` (English US);
that layout must be installed. The driver saves and restores the original layout
ID. It does not query the Chinese/English mode inside that layout. Native Windows
input behavior has not yet been tested for this driver.

Windows 终端会话默认使用 `im_select` 驱动。安装上述 `im-select.exe` 并放入 `PATH`，
也可以配置完整路径。默认 ASCII 布局 ID 为 `"1033"`（美式英语），需要先安装该布局。
驱动保存并恢复原布局 ID，不查询同一布局内部的中英文模式。目前尚未实测此驱动在
Windows 上的实际输入行为。

```lua
require("imselect").setup({
  default_driver = { Windows_NT = "im_select" },
  im_select = {
    command = "im-select.exe", -- Or a full path / 或完整路径
    ascii = "1033",
  },
})
```

Alternatively, the `winime` driver controls the foreground input window's IME
open status through LuaJIT FFI and the system `user32`/`imm32` DLLs. It requires
native Windows Neovim with LuaJIT; it does not require AutoHotkey or an external
command. It saves and restores the open status without changing the layout or
conversion mode. API delivery failures/timeouts are reported as errors. This
driver's actual behavior with Windows terminals and IMEs still needs testing.

也可使用 `winime` 驱动，通过 LuaJIT FFI 和系统自带的 `user32`、`imm32` DLL 控制
前台输入窗口的 IME 开关。它需要原生 Windows Neovim 和 LuaJIT，无需 AutoHotkey
或外部命令。驱动保存和恢复开关状态，不主动修改布局及转换模式；API 消息发送
失败或超时会报错。目前仍需在 Windows 终端和输入法上实测其实际行为。

```lua
require("imselect").setup({
  default_driver = { Windows_NT = "winime" },
})
```

### Kitty

kitty driver uses `OSC 1337;SetUserVar=im=temp_ascii|restore`, so it can ask the
local kitty instance to temporarily use ASCII input and later restore the
previous input method even from SSH sessions when kitty is configured with a
matching watcher. It does not query the real input method state.
Copy `examples/kitty-im-control.py` to your kitty config directory and add its
absolute path to `kitty.conf`:
```conf
watcher /path/to/kitty-im-control.py
```
Edit `IS_ACTIVE_CMD`, `IS_ACTIVE_OUTPUT`, `TEMP_ASCII_CMD`, and `RESTORE_CMD` at
the top of that file if you do not use fcitx5. Inside tmux, enable passthrough:
```tmux
set -g allow-passthrough on
```
For SSH terminal sessions, the default `kitty` driver requires a local Kitty
terminal with the watcher above; imselect does not detect the terminal type.
SSH detection uses `SSH_TTY`, `SSH_CONNECTION`, or `SSH_CLIENT`.
SSH 终端会话默认使用的 `kitty` 驱动需要本地 Kitty 配合上述 watcher；插件不会检测
终端类型。SSH 环境通过 `SSH_TTY`、`SSH_CONNECTION` 或 `SSH_CLIENT` 判断。
The driver sends OSC with `nvim_ui_send()` like Neovim's OSC52 provider. If your
tmux path needs explicit passthrough wrapping outside of auto SSH detection, use:
```lua
require("imselect").setup({
  default_driver = { Linux = "kitty", Darwin = "kitty" },
  kitty = { tmux_passthrough = true },
  enable_in_ssh = true,
})
```
## Syntax-aware switching / 语法感知

The default strategy uses Neovim's built-in Tree-sitter API in Insert mode:
code temporarily selects ASCII (`temp_ascii()`); strings, comments, and prose
restore the saved input method (`restore()`). Moving between regions or editing
text updates the classification. Normal mode still uses ASCII, and `/` / `?`
searches restore the input method.

默认策略在插入模式下通过 Neovim 原生 Tree-sitter API 判断语法：代码区临时使用
英文（`temp_ascii()`），字符串、注释和正文恢复原输入法（`restore()`）。移动光标
或修改文本时更新判断。普通模式仍使用英文，`/`、`?` 搜索恢复输入法。

Install parsers for the languages you edit; neither pairwise.nvim nor
nvim-treesitter is a runtime dependency, and highlighting need not be enabled.
Without a usable parser, switching keeps its previous mode-only behavior.
Markdown prose, inline code and code blocks are distinguished; injected languages
use their own syntax, so a comment inside a Lua code block can still use Chinese.
HTML/Vue text and quoted attributes are also treated as text. With a LaTeX
parser, prose and `\text{...}` restore input; math and recognized code environments
select ASCII. Verbatim content follows the parser's `comment` classification and
restores input. There is no special handling for inline `\verb`.
The separate nvimtex strategy has been removed.

请为编辑的语言安装 parser；运行时不依赖 pairwise.nvim 或 nvim-treesitter，也不要求
开启高亮。没有可用 parser 时保留原先只按模式切换的行为。Markdown 区分正文、
行内代码和代码块；注入语言按自身语法判断，因此 Lua 代码块中的注释仍可输入中文。
HTML/Vue 的文本和带引号的属性值也按文本处理。安装 LaTeX parser 后，正文和
`\text{...}` 恢复输入法，数学区及已识别的代码环境使用英文。verbatim 内容沿用
parser 的 `comment` 分类，恢复输入法；行内 `\verb` 不做特殊处理。独立的 nvimtex
策略已移除。

This is a basic node-type classification, not a complete language semantic model.
Common string/comment nodes are text; recognized interpolation nodes are code;
unrecognized nodes follow their nearest classified ancestor, otherwise code.
Incomplete input follows the parser's current tree. A custom default `inspecter`
replaces this built-in decision.

这是按节点类型分类的基础版，不是完整的语言语义模型。常见字符串、注释节点属于
文本，已识别的插值节点属于代码；未知节点向上查找最近的分类，均未命中则按代码
处理。未完成输入的结果取决于 parser 当前的语法树；自定义默认策略的 `inspecter`
会替换这项内置判断。

## Custom strategy / 自定义策略

Override `strategy.strategy_provider.default.inspecter` with a function receiving
the buffer number. Return `true` to restore input or `false` to temporarily use ASCII.

可通过 `strategy.strategy_provider.default.inspecter` 提供接收缓冲区编号的判断函数：
返回 `true` 恢复输入法，返回 `false` 临时使用英文。

## Custom drivers / 自定义驱动

A driver module exports `setup(opts)`, returning a driver with either:

- `temp_ascii()` and `restore()`, managing its own temporary state; or
- `get_state()`, `set_state(state)`, and an `ascii_state` value. The shared helper
  saves the original state once, switches to `ascii_state`, and restores the exact
  saved value. States can be booleans or strings such as input source IDs.

驱动模块导出 `setup(opts)`，返回的驱动支持以下两种方式之一：

- 实现 `temp_ascii()`、`restore()`，自行管理临时状态。
- 实现 `get_state()`、`set_state(state)`，并提供 `ascii_state`。公共 helper 只保存
  一次原状态，临时切换至 `ascii_state`，恢复时原样写回。状态可以是布尔值，也可以
  是输入源 ID 等字符串。

The previous `is_active/active/disable` interface is replaced by this state API.
For example, macism now restores the actual previous source instead of selecting
a fixed Chinese source. Its ASCII source defaults to `com.apple.keylayout.ABC`
and can be configured with `macism = { ascii = "input.source.id" }`.

原先的 `is_active/active/disable` 接口统一替换为上述状态 API。例如 macism 现在恢复
实际保存的输入源，而非固定的中文输入源。默认 ASCII 输入源为 `com.apple.keylayout.ABC`，
可通过 `macism = { ascii = "input.source.id" }` 修改。

Drivers can use `require("imselect.util").find_executable({ "command", "/fallback/path" })`
to select the first executable candidate. This helper now accepts an ordered list
instead of a command string; each driver owns its platform-specific candidates.

驱动可使用 `require("imselect.util").find_executable({ "命令名", "/备用路径" })`
选择第一个可执行项。此 helper 现在统一接收有序列表，不再接收单个命令字符串；
各平台的候选命令及安装路径由对应驱动管理。

Use `util.run({ command, ... })` in command-based drivers to get trimmed stdout;
it raises an error on a nonzero exit, signal, or a 1-second timeout. For async
queries, `util.run(args, function(output, err) ... end)` returns a `vim.SystemObj`
and passes `nil, err` to the callback on command failure. Drivers interpret the
output as their own state; asynchronous `get_state` callbacks can also receive
`nil, err` on command failure.

外部命令驱动可用 `util.run({ command, ... })` 获取去除首尾空白的标准输出；非零退出、
信号终止或超过 1 秒超时会报错。异步查询使用
`util.run(args, function(output, err) ... end)`，返回 `vim.SystemObj`，命令失败时回调
接收 `nil, err`。输出如何转为状态由驱动负责；异步 `get_state` 回调也可以接收
`nil, err` 来识别命令失败。

# install 
you can install with `lazy.nvim` or other manager. 
```lua
	{
		"dirichy/imselect.nvim",
		config = true,
	},

```
