# imselect.nvim

[English](README.md) · [简体中文](README.zh-CN.md)

**Write code, comments, and equations. Leave input method switching to Neovim.**

Normal mode needs ASCII. Your comments need Chinese. A LaTeX sentence needs both — sometimes several times before you ever press Escape.

imselect follows **what you are editing**, as well as your mode. It selects ASCII for code and math, restores your input method for text, and respects a manual choice while the editing context stays the same.

![Continuous LaTeX editing with zero manual input method switches](https://github.com/dirichy/imselect.nvim/releases/download/demos/demo.gif)

*Chinese prose → math → prose → Chinese inside `\text{...}` → a summation formula. One continuous Insert session. **0 manual input method switches.** Real fcitx5-rime input, with Neovim's built-in snippets for formula entry and field jumps.*

[HD video](https://github.com/dirichy/imselect.nvim/releases/download/demos/demo.mp4) · [Reproduce all demos](demos/README.md)

## Beyond switching on Escape

Mode switching is the starting point. The details matter during a real editing session:

| When you… | imselect… |
| --- | --- |
| Move between code, strings, and comments | Switches at the syntax boundary, even within Insert mode |
| Jump into math or a formula's `\text{...}` field | Follows the new context, including snippet field jumps |
| Search with `/` or `?`, then run a `:` command | Restores input for searches; keeps commands in ASCII |
| Manually choose an input method in code | Leaves your choice alone while the context classification stays unchanged |
| Open or close Insert completion (`ic` / `ix`) | Keeps the same Insert-mode policy |
| Press Escape after a manual change | Reconciles ASCII again, even when you were already in a code region |
| Return to text after an ASCII-only context | Restores the saved driver state, without a hardcoded Chinese input source |
| Edit over SSH in Kitty | Controls the local input method through a local watcher |

Tree-sitter supplies context; a driver controls the input method. No per-language switching shortcuts, polling loop, or snippet plugin is required. Without a usable parser, mode-aware switching still works.

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

## How it works

### Mode-aware switching

| Editing mode | Input behavior |
| --- | --- |
| Normal, Visual, etc. | Temporarily select ASCII |
| Insert | Follow the editing context |
| Search (`/` and `?`) | Restore input |
| Other command-line modes | Temporarily select ASCII |

![Editing, Chinese searches, and Ex commands without manual input method switching](https://github.com/dirichy/imselect.nvim/releases/download/demos/modes.gif)

*Type Chinese, press Escape, search forward and backward in Chinese, resume editing, then run `:set number`. **0 manual input method switches.*** [HD video](https://github.com/dirichy/imselect.nvim/releases/download/demos/modes.mp4)

Restoration preserves the input state saved by the driver. You do not have to configure a fixed “Chinese input method” to return to.

### Syntax-aware switching

Write a Chinese string, add comments, calculate a value in ASCII, and append another Chinese comment:

![Chinese strings and comments alongside ASCII Lua code](https://github.com/dirichy/imselect.nvim/releases/download/demos/code.gif)

*Real Chinese composition in strings and comments; ASCII for `local total = 6 * 7`. Even typing `-- ` at the end of a code line restores Chinese input. **0 manual input method switches.*** [HD video](https://github.com/dirichy/imselect.nvim/releases/download/demos/code.mp4)

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

Injected languages are handled independently. For example, comments inside a Lua code block in Markdown can still use your native input method.

Switching happens as you move the cursor or edit text, without leaving Insert mode.

Behavior follows the parser's current syntax tree, including incomplete syntax. An unrecognized node inherits its nearest classified ancestor; with no matching classification, it uses ASCII. See the [classification rules](lua/imselect/syntax.lua) for recognized node types.

### Automatic, but not intrusive

Automatic input method switching should help you, not fight you.

Suppose you are editing a code region:

1. imselect temporarily selects ASCII.
2. You manually switch to another input method.
3. You continue typing, moving the cursor, or using completion.
4. Your manual choice remains untouched while the context classification stays unchanged.
5. Press Escape, and imselect selects ASCII again.

Even though both the code region and Normal mode normally require ASCII, entering Normal mode reasserts that requirement.

Completion submodes (`ic` and `ix`) are treated as part of Insert mode. Opening or closing a completion menu does not itself override your input method choice.

### Switch only when necessary

Rather than continuously enforcing an input method state, imselect responds to changes in editing requirements.

It evaluates the current editing context, but avoids querying or modifying the input method when the requirement remains unchanged, except at boundaries that require reconciliation.

This reduces unnecessary driver calls while naturally preserving manual input method choices.

See [Input method state design](docs/input-state.md) for the state coordination model and regression coverage.

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

Executable-based drivers are selected according to command availability. On unsupported systems, or when no suitable Linux/macOS executable is found, initialization is skipped.

Executable detection does not verify that the corresponding input method is running. SSH detection assumes that the local Kitty watcher has been configured; it does not detect the terminal type.

## Configuration

The default configuration is intended to work with minimal setup.

```lua
require("imselect").setup({
    -- Automatically select a driver by default.
    -- Set a driver name to override detection.
    -- Set false to disable initialization.
    driver = "fcitx",

    -- Restore input on FocusLost and reconcile on FocusGained.
    focus_event = false,
})
```

Omit `driver` to use automatic detection.

### Custom driver selection

The `driver` option also accepts a function receiving the merged configuration. It is called once during setup.

Return a driver name to enable it, or `false` / `nil` to skip initialization.

For example, disable imselect over SSH and use macism for local macOS sessions:

```lua
require("imselect").setup({
    driver = function()
        if require("imselect.util").is_ssh() then
            return false
        end

        if vim.g.neovide then
            return "neovide"
        end

        return ({
            Linux = "fcitx",
            Darwin = "macism",
            Windows_NT = "im_select",
        })[vim.uv.os_uname().sysname]
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

The driver remembers the previous input source ID and restores it when needed.

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

It controls the foreground window's IME open status through LuaJIT FFI, without AutoHotkey or external executables.

**Note:** Both Windows drivers still require native Windows testing.

### Kitty and SSH

imselect can control the input method on your local machine even when Neovim is running on a remote server.

The Kitty driver sends OSC user-variable messages through the terminal connection. A local watcher receives these requests and manages the input method.

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

No direct connection from the remote Neovim instance to the local input method service is required.

## Extending imselect

Input method control and editing-context classification are independent.

- A **driver** determines how to control the input method.
- A **strategy** determines when the current Insert-mode context should use ASCII or restore input.

### Custom strategies

Override the default cursor inspector:

```lua
require("imselect").setup({
    strategy = {
        strategy_provider = {
            default = {
                inspecter = function(bufnr)
                    return vim.bo[bufnr].filetype == "text"
                end,
            },
        },
    },
})
```

The inspector receives the buffer number and returns:

- `true`: restore the saved input state.
- `false`: temporarily select ASCII.

Inspectors are evaluated only in Insert mode, including completion submodes. Mode requirements are handled independently by the core.

### Custom drivers

A driver module exports `setup(opts)` and returns either a state-based driver:

```lua
{
    ascii_state = ...,
    get_state = function() ... end,
    set_state = function(state) ... end,
}
```

Or a driver that manages temporary input states directly:

```lua
{
    temp_ascii = function() ... end,
    restore = function() ... end,
}
```

State-based drivers automatically receive the shared state restoration mechanism.

States may be booleans or strings, depending on the underlying input method API.

Direct drivers must reconcile manual input method changes on repeated ASCII requests, rather than simply ignoring requests when a saved state already exists.

See the [driver implementations](lua/imselect/driver/) for examples.

## Documentation and development

- [Input method state design](docs/input-state.md)
- [Regression tests](tests/README.md)
- [Demo recording and verification](demos/README.md)

## License

[MIT](LICENSE)
