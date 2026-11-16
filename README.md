This plugin is to switch im autometically in neovim. 
# features
## force ascii mode in normal mode
## multi driver.
including fcitx, macism, neovide. and user can provide thier own driver, too. 

Drivers are selected once during `setup()`, in this order:

1. Neovide always uses the `neovide` driver, regardless of SSH environment variables.
2. Other SSH sessions use `default_driver.ssh` (default: `"kitty"`). Setting
   `enable_in_ssh = false` disables imselect in these sessions only.
3. Other sessions use `default_driver[os]`, where `os` is `Linux`, `Darwin`, etc.

驱动在 `setup()` 时按以下顺序选择一次：

1. Neovide 始终使用 `neovide` 驱动，不受 SSH 环境变量影响。
2. 其他 SSH 会话使用 `default_driver.ssh`，默认为 `"kitty"`。
   `enable_in_ssh = false` 只在这些会话中禁用 imselect。
3. 其余会话使用 `default_driver[os]`，其中 `os` 为 `Linux`、`Darwin` 等系统名。

```lua
require("imselect").setup({
  default_driver = { Linux = "fcitx", Darwin = "fcitx", ssh = "kitty" },
  enable_in_ssh = true,
})
```

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
# install 
you can install with `lazy.nvim` or other manager. 
```lua
	{
		"dirichy/imselect.nvim",
		config = true,
	},

```
