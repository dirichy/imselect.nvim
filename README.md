This plugin is to switch im autometically in neovim. 
# features
## force ascii mode in normal mode
## multi driver.
including fcitx, macism, neovide. and user can provide thier own driver, too. 
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
When using this driver from SSH, configure imselect to use `kitty` for that
session; inside remote tmux, `$TERM` is usually `tmux-256color`.
The driver sends OSC with `nvim_ui_send()` like Neovim's OSC52 provider. If your
tmux path needs explicit passthrough wrapping, use:
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
