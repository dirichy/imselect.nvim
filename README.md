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
Edit `IS_ACTIVE_CMD`, `TEMP_ASCII_CMD`, and `RESTORE_CMD` at the top of that
file if you do not use fcitx5.
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
