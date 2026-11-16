This plugin is to switch im autometically in neovim. 
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
## custom strategy. 
beside neovim mode, you can provide any function to judge if we should use ascii mode. 
for example, I implemented a features to force ascii mode in `latex` math mode with [nvimtex.nvim](https://github.com/dirichy/nvimtex.nvim).

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

# install 
you can install with `lazy.nvim` or other manager. 
```lua
	{
		"dirichy/imselect.nvim",
		config = true,
	},

```
