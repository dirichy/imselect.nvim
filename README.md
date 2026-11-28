# imselect.nvim

[English](README.md) · [简体中文](README.zh-CN.md)

**Write code, comments, and equations. Leave input method switching to Neovim.**

Normal mode needs ASCII. Your comments need Chinese. A LaTeX sentence needs both — sometimes several times before you ever press Escape.

imselect follows **what you are editing**, as well as your mode. It selects ASCII for code and math, restores your input method for text, and respects a manual choice while the editing context stays the same.

![Continuous LaTeX editing with zero manual input method switches](https://github.com/dirichy/imselect.nvim/releases/download/demos/demo.gif)

*Chinese prose → math → prose → Chinese inside `\text{...}` → a summation formula. One continuous Insert session. **0 manual input method switches.***

[HD video](https://github.com/dirichy/imselect.nvim/releases/download/demos/demo.mp4)

## Beyond switching on Escape

Mode switching is the starting point. The details matter during a real editing session:

| When you… | imselect… |
| --- | --- |
| Move between code, strings, and comments | Switches at the syntax boundary, even within Insert mode |
| Jump into math or a formula's `\text{...}` field | Follows the new context, including snippet field jumps |
| Search with `/` or `?`, then run a `:` command | Restores input for searches; keeps commands in ASCII |
| Manually choose an input method in code | Preserves your choice while you stay in the same editing context |
| Edit over SSH in Kitty | Controls the local input method through a local watcher |

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "dirichy/imselect.nvim",
    config = true,
}
```

Or use your preferred plugin manager and call:

```lua
require("imselect").setup()
```

The appropriate driver is selected automatically in supported environments.

Install the Tree-sitter parsers for the languages you edit to enable syntax-aware switching. Neither `nvim-treesitter` nor Tree-sitter highlighting is required.

Without a usable parser, imselect falls back to mode-aware switching.

## Switching behavior

### Mode-aware switching

| Editing mode | Input behavior |
| --- | --- |
| Normal, Visual, etc. | Temporarily select ASCII |
| Insert | Follow the editing context |
| Search (`/` and `?`) | Restore input |
| Other command-line modes | Temporarily select ASCII |

![Editing, Chinese searches, and Ex commands without manual input method switching](https://github.com/dirichy/imselect.nvim/releases/download/demos/modes.gif)

*Type Chinese, press Escape, search forward and backward in Chinese, resume editing, then run `:set number`. **0 manual input method switches.*** [HD video](https://github.com/dirichy/imselect.nvim/releases/download/demos/modes.mp4)

Your previous input method is restored automatically when you return to text.

### Syntax-aware switching

Write a Chinese string, add comments, calculate a value in ASCII, and append another Chinese comment:

![Chinese strings and comments alongside ASCII Lua code](https://github.com/dirichy/imselect.nvim/releases/download/demos/code.gif)

*Write Chinese strings and comments, then continue writing code. **0 manual input method switches.*** [HD video](https://github.com/dirichy/imselect.nvim/releases/download/demos/code.mp4)

| Context | Input behavior |
| --- | --- |
| Source code | ASCII |
| Comments and strings | Restore |
| String interpolation | ASCII |
| Markdown prose | Restore |
| Markdown inline code | ASCII |
| LaTeX prose | Restore |
| LaTeX math | ASCII |
| LaTeX `\text{...}` | Restore |
| HTML/Vue text and quoted attributes | Restore |

In Markdown code blocks, code uses ASCII while comments and strings can still use your native input method.

Switching happens as you move the cursor or edit text, without leaving Insert mode.

Context detection depends on the language parser; incomplete syntax can affect the result.

## Supported drivers

| Driver | Environment | Requirements |
| --- | --- | --- |
| `fcitx` | Linux, macOS | Fcitx 4 or Fcitx 5 |
| `fcitx_dbus` | Linux | Fcitx 5, LuaJIT, `libdbus-1.so.3` |
| `fcitx_macos_direct` | macOS | Fcitx5 macOS, LuaJIT; system libcurl and Carbon |
| `macism` | macOS | `macism` executable |
| `neovide` | Neovide | None |
| `kitty` | Local or remote Kitty sessions | Local Kitty watcher |
| `im_select` | Windows, WSL | `im-select.exe` |
| `winime` | Windows | Native Neovim with LuaJIT |
| `wsl` | WSL | Windows PowerShell (`powershell.exe`), with WSL interop enabled |

### Automatic driver selection

By default, imselect selects drivers in the following order:

- Neovide sessions: `neovide`
- SSH sessions: `kitty`
- WSL: `im_select`, then `wsl` (PowerShell)
- Linux: `fcitx`
- macOS: `fcitx`, then `macism`
- Windows: `im_select`, then `winime`

Your input method must be installed and running. If no supported driver is available, initialization is skipped. For SSH sessions, configure the [local Kitty watcher](#kitty-and-ssh), or override driver selection below.

## Configuration

The default configuration is intended to work with minimal setup.

```lua
require("imselect").setup({
    -- Automatically select a driver by default.
    -- Set a driver name to override detection.
    -- Set false to disable initialization.
    driver = "fcitx",

    -- Enable to restore input when unfocused and resume automatic switching on focus.
    focus_event = false,
})
```

Omit `driver` to use automatic detection.

### Custom inspectors

Inspectors classify the Insert-mode cursor context: `true` restores input, `false`
selects ASCII. Selection order is **buffer > filetype > global**, with built-in
syntax detection as the default.

```lua
local imselect = require("imselect")
imselect.setup({
    inspector = function(bufnr) -- Optional global override.
        return vim.bo[bufnr].filetype == "text"
    end,
})

imselect.set_inspector(function() return true end, { filetype = { "text", "markdown" } })
imselect.set_inspector(function() return false end, { buffer = true }) -- Current buffer.
imselect.set_inspector(nil, { buffer = true }) -- Remove the buffer override.
```

Use `set_inspector(fn)` to change the global inspector. Passing `nil` removes an
override; removing the global override restores built-in syntax detection. Changes
take effect on the next update; call `imselect.update()` to apply immediately.
Buffer inspectors are released on `BufWipeout`. Normal mode and command-line
behavior remain governed by the [mode rules](#mode-aware-switching).

### Custom driver selection

The `driver` option also accepts a function returning a driver name, or `false` / `nil` to skip initialization.

For example, on macOS, disable imselect over SSH and use macism locally:

```lua
require("imselect").setup({
    driver = function()
        if require("imselect.util").is_ssh() then
            return false
        end

        return "macism"
    end,
})
```

Driver-specific options are configured under their corresponding module names.

### Linux: direct D-Bus

On Linux with Fcitx 5, `fcitx_dbus` is a faster alternative to the command-based
`fcitx` driver, with the same active-state switching and restoration. Select it explicitly:

```lua
require("imselect").setup({
    driver = "fcitx_dbus",
})
```

Requires Neovim with LuaJIT and the system `libdbus-1.so.3`; no Lua D-Bus package
is needed. It reuses a session bus connection, avoiding the process overhead of
`fcitx5-remote`, and saves/restores the input method's active state. Calls wait
synchronously for a reply with a one-second timeout. Fcitx 4 is unsupported;
automatic driver selection is unchanged. Use the local Kitty watcher over SSH.

### macOS: direct Fcitx5 communication (experimental)

Fcitx5 macOS uses HTTP rather than D-Bus. This experimental driver bypasses the
CLI wrappers to reduce call overhead. Select it explicitly:

```lua
require("imselect").setup({
    driver = "fcitx_macos_direct",
})
```

Uses system libcurl for the Fcitx5 HTTP API and Carbon to check the selected system
input source, avoiding the `fcitx5-remote`, `fcitx5-curl`, `curl`, and `get_im`
processes. Automatic driver selection is unchanged; no extra libraries are needed.

Like the upstream script, reads `~/.config/fcitx5/conf/beast.conf` for Unix socket
or local TCP settings, defaulting to `/tmp/fcitx5.sock`. Configuration is read at
setup; restart Neovim after changing it. Synchronous requests time out after one
second. The upstream server currently closes each connection, so only the libcurl
handle is reused. Native macOS validation and performance measurements are still
pending. It depends directly on the Beast HTTP API, which may change between
Fcitx5 macOS versions. Use `fcitx` if compatibility issues arise.

### macOS

Install [macism](https://github.com/laishulu/macism) if you use the `macism` driver.

```lua
require("imselect").setup({
    driver = "macism",
    macism = {
        ascii = "com.apple.keylayout.ABC",
    },
})
```

Your previous input source is restored automatically when needed.

### Windows

For the `im_select` driver, install [im-select.exe](https://github.com/daipeihust/im-select)
and add it to `PATH`, or set `im_select.command` to its full path.

```lua
require("imselect").setup({
    driver = "im_select",
    im_select = {
        command = "im-select.exe",
        ascii = "1033",
    },
})
```

The default ASCII layout is US English, which must be installed. This driver saves and restores keyboard layout IDs, not the conversion mode within a layout.

Alternatively, use the native `winime` driver:

```lua
require("imselect").setup({
    driver = "winime",
})
```

It controls the foreground window's IME directly, without external executables.

**Note:** Both Windows drivers still require native Windows testing.

### WSL

The Windows host's input method is controlled automatically: `im-select.exe` is
preferred, with system PowerShell used when it is unavailable. Enable WSL interop
for Windows executables; no additional configuration is needed.

For custom executable locations, use WSL paths in `im_select.command` or
`wsl.command`. Set `driver = "wsl"` to use PowerShell directly, or
`driver = "fcitx"` for a Linux input method under WSLg.

**Note:** WSL support still requires testing on a real system.

### Kitty and SSH

imselect can control the input method on your local machine even when Neovim is running on a remote server.

Set up the watcher on your local machine:

1. Copy [kitty-im-control.py](examples/kitty-im-control.py) to your local Kitty configuration directory.
2. Add its absolute path to `kitty.conf`:

```conf
watcher /path/to/kitty-im-control.py
```

3. If you do not use Fcitx 5, adjust the input method commands at the top of the watcher.

When using tmux, enable passthrough:

```tmux
set -g allow-passthrough on
```

Kitty passthrough wrapping is enabled by default in SSH sessions. You can also configure it explicitly:

```lua
require("imselect").setup({
    driver = "kitty",
    kitty = {
        tmux_passthrough = true,
    },
})
```

## Documentation and development

- [Custom inspectors and drivers](docs/extending.md)
- [Input method state design](docs/input-state.md)
- [Regression tests](tests/README.md)
- [Demo recording and verification](demos/README.md)

## License

[MIT](LICENSE)
