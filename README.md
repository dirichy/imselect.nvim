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
| `macism` | macOS | `macism` executable |
| `neovide` | Neovide | None |
| `kitty` | Local or remote Kitty sessions | Local Kitty watcher |
| `im_select` | Windows | `im-select.exe` |
| `winime` | Windows | Native Neovim with LuaJIT |

### Automatic driver selection

By default, imselect selects drivers in the following order:

- Neovide sessions: `neovide`
- SSH sessions: `kitty`
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

The `im_select` driver requires [im-select.exe](https://github.com/daipeihust/im-select).

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

- [Custom strategies and drivers](docs/extending.md)
- [Input method state design](docs/input-state.md)
- [Regression tests](tests/README.md)
- [Demo recording and verification](demos/README.md)

## License

[MIT](LICENSE)
