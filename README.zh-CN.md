# imselect.nvim

[English](README.md) · [简体中文](README.zh-CN.md)

**专心写代码、注释和公式，让 Neovim 帮你切换输入法。**

普通模式需要英文，注释需要中文，LaTeX 正文和公式之间又要来回切换——有时还没按一次 Escape，就已经切了好几轮。

imselect 同时关注你的编辑模式和**正在编辑的内容**：代码和公式自动使用 ASCII，正文恢复原来的输入法；上下文不变时，保留你的手动选择。

![连续编辑 LaTeX，手动切换输入法 0 次](https://github.com/dirichy/imselect.nvim/releases/download/demos/demo-zh.gif)

*中文正文 → 公式 → 正文 → `\text{...}` 中的中文 → 求和公式。全程保持 Insert 模式，**手动切换输入法 0 次**。*

[高清视频](https://github.com/dirichy/imselect.nvim/releases/download/demos/demo-zh.mp4)

## 从按 Escape 切英文，到整个编辑过程

模式切换只是起点，日常编辑中的这些细节也都照顾到了：

| 当你…… | imselect 会…… |
| --- | --- |
| 在代码、字符串和注释之间移动 | 跟随语法边界切换，即使一直处于 Insert 模式 |
| 跳入公式或公式的 `\text{...}` 字段 | 根据新上下文切换，也支持 snippet 字段跳转 |
| 用 `/` 或 `?` 搜索，再执行 `:` 命令 | 搜索时恢复输入法，命令中保持 ASCII |
| 在代码中手动切换输入法 | 当前编辑上下文不变时保留你的选择 |
| 在 Kitty 中通过 SSH 编辑 | 通过本地 watcher 控制本机输入法 |

## 安装

使用 [lazy.nvim](https://github.com/folke/lazy.nvim)：

```lua
{
    "dirichy/imselect.nvim",
    config = true,
}
```

也可以使用其他插件管理器，再调用：

```lua
require("imselect").setup()
```

在支持的环境中，插件会自动选择合适的驱动。

安装所编辑语言的 Tree-sitter parser，即可启用语法感知切换。无需安装 `nvim-treesitter`，也无需启用 Tree-sitter 高亮。

没有可用的 parser 时，imselect 会退回按模式切换。

## 切换规则

### 按模式切换

| 编辑模式 | 输入行为 |
| --- | --- |
| Normal、Visual 等 | 临时切换为 ASCII |
| Insert | 跟随当前编辑上下文 |
| 搜索（`/` 和 `?`） | 恢复输入法 |
| 其他命令行模式 | 临时切换为 ASCII |

![编辑、中文搜索和 Ex 命令，全程无需手动切换输入法](https://github.com/dirichy/imselect.nvim/releases/download/demos/modes-zh.gif)

*输入中文，按 Escape，向前和向后搜索中文，继续编辑，再执行 `:set number`。**手动切换输入法 0 次。*** [高清视频](https://github.com/dirichy/imselect.nvim/releases/download/demos/modes-zh.mp4)

返回正文时，会自动恢复之前使用的输入法。

### 按语法切换

写中文字符串、添加注释、用 ASCII 输入计算式，再追加中文行尾注释：

![Lua 代码与中文字符串、注释混合编辑](https://github.com/dirichy/imselect.nvim/releases/download/demos/code-zh.gif)

*写中文字符串和注释，再继续写代码。**手动切换输入法 0 次。*** [高清视频](https://github.com/dirichy/imselect.nvim/releases/download/demos/code-zh.mp4)

| 上下文 | 输入行为 |
| --- | --- |
| 源代码 | ASCII |
| 注释和字符串 | 恢复输入法 |
| 字符串插值表达式 | ASCII |
| Markdown 正文 | 恢复输入法 |
| Markdown 行内代码 | ASCII |
| LaTeX 正文 | 恢复输入法 |
| LaTeX 公式 | ASCII |
| LaTeX `\text{...}` | 恢复输入法 |
| HTML/Vue 文本和带引号的属性值 | 恢复输入法 |

Markdown 代码块中，代码使用 ASCII，注释和字符串仍可使用中文输入法。

移动光标或编辑文本即可触发切换，无需退出 Insert 模式。

上下文识别依赖语言 parser，尚未完成的语法可能影响判断结果。

## 支持的驱动

| 驱动 | 适用环境 | 依赖 |
| --- | --- | --- |
| `fcitx` | Linux、macOS | Fcitx 4 或 Fcitx 5 |
| `fcitx_dbus` | Linux | Fcitx 5、LuaJIT、`libdbus-1.so.3` |
| `fcitx_macos_direct` | macOS | Fcitx5 macOS、LuaJIT；系统 libcurl 与 Carbon |
| `macism` | macOS | `macism` 可执行文件 |
| `neovide` | Neovide | 无 |
| `kitty` | 本地或远程 Kitty 会话 | 本地 Kitty watcher |
| `im_select` | Windows、WSL | `im-select.exe` |
| `winime` | Windows | 带 LuaJIT 的原生 Windows Neovim |
| `wsl` | WSL | Windows 自带的 `powershell.exe`，需启用 WSL 互操作 |

### 自动选择驱动

默认按以下顺序选择：

- Neovide 会话：`neovide`
- SSH 会话：`kitty`
- WSL：`im_select`，其次 `wsl`（PowerShell）
- Linux：`fcitx`
- macOS：`fcitx`，其次 `macism`
- Windows：`im_select`，其次 `winime`

请先安装并启动输入法。没有可用的受支持驱动时，插件会跳过初始化。SSH 会话需要配置[本地 Kitty watcher](#kitty-与-ssh)，或通过下面的配置覆盖驱动选择。

## 配置

默认配置尽量做到开箱即用。

```lua
require("imselect").setup({
    -- 默认自动选择驱动。
    -- 指定驱动名称可覆盖自动检测。
    -- 设为 false 则跳过初始化。
    driver = "fcitx",

    -- 启用后，失去焦点时恢复输入法，获得焦点时继续自动切换。
    focus_event = false,
})
```

省略 `driver` 即可使用自动检测。

### 自定义驱动选择

`driver` 也可以是函数：返回驱动名称即可启用，返回 `false` 或 `nil` 则跳过初始化。

例如，在 macOS 上，SSH 会话禁用 imselect，本地会话使用 macism：

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

各驱动的专用选项放在对应模块名下。

### Linux：直接调用 D-Bus

Linux 使用 Fcitx 5 时，`fcitx_dbus` 是命令行 `fcitx` 驱动的更快替代方案，
保留相同的输入法开关与恢复行为。需要显式选择：

```lua
require("imselect").setup({
    driver = "fcitx_dbus",
})
```

需要带 LuaJIT 的 Neovim 和系统 `libdbus-1.so.3`，无需安装 Lua D-Bus 包。
它复用会话总线连接，省去每次调用 `fcitx5-remote` 的进程开销，保存和恢复输入法开关。
调用同步等待回复，超时为 1 秒；不支持 Fcitx 4，也不自动参与驱动选择。
SSH 会话应继续使用本地 Kitty watcher。

### macOS：Fcitx5 直接通信（实验性）

Fcitx5 macOS 使用 HTTP，而不是 D-Bus。此实验性驱动绕过命令行 wrapper，
旨在降低调用开销，需要显式选择：

```lua
require("imselect").setup({
    driver = "fcitx_macos_direct",
})
```

通过系统 libcurl 调用 Fcitx5 的 HTTP 接口，用 Carbon 检查当前系统输入源，
省去 `fcitx5-remote`、`fcitx5-curl`、`curl` 和 `get_im` 的进程启动。
默认驱动选择不变，无需安装额外库。

与上游脚本一样，读取 `~/.config/fcitx5/conf/beast.conf`，支持 Unix socket 和本机 TCP；
没有配置时使用 `/tmp/fcitx5.sock`。配置在初始化时读取，修改后需重启 Neovim。
同步请求超时为 1 秒。当前上游服务端每次请求后关闭连接，因此只复用 libcurl 句柄。
此驱动尚待 macOS 实机验证与性能测量。它直接依赖 Beast HTTP API，
可能受 Fcitx5 macOS 版本变化影响；遇到兼容问题时可改用 `fcitx`。

### macOS

使用 `macism` 驱动时，先安装 [macism](https://github.com/laishulu/macism)。

```lua
require("imselect").setup({
    driver = "macism",
    macism = {
        ascii = "com.apple.keylayout.ABC",
    },
})
```

需要时会自动恢复之前使用的输入源。

### Windows

使用 `im_select` 驱动时，安装 [im-select.exe](https://github.com/daipeihust/im-select) 并加入 `PATH`，
或通过 `im_select.command` 指定完整路径。

```lua
require("imselect").setup({
    driver = "im_select",
    im_select = {
        command = "im-select.exe",
        ascii = "1033",
    },
})
```

默认 ASCII 布局为美式英语，需事先安装。此驱动保存和恢复键盘布局 ID，不包含同一布局内部的中英文转换状态。

也可以使用原生 `winime` 驱动：

```lua
require("imselect").setup({
    driver = "winime",
})
```

它直接控制前台窗口的 IME 开关，无需外部可执行文件。

**注意：** 两个 Windows 驱动都仍需原生 Windows 实机测试。

### WSL

默认控制 Windows 宿主输入法：优先使用 `im-select.exe`，未安装时自动使用系统 PowerShell。
启用 WSL 的 Windows 程序互操作后，无需额外配置。

自定义程序路径使用 WSL 路径：`im_select.command` 指定 `im-select.exe`，
`wsl.command` 指定 PowerShell。需要直接使用 PowerShell 时，设置 `driver = "wsl"`。
若在 WSLg 中使用 Linux 输入法，设置 `driver = "fcitx"`。

**注意：** WSL 支持尚待实机验证。

### Kitty 与 SSH

即使 Neovim 运行在远程服务器上，imselect 也能控制本机输入法。

在本机配置 watcher：

1. 将 [kitty-im-control.py](examples/kitty-im-control.py) 复制到本机 Kitty 配置目录。
2. 在 `kitty.conf` 中添加它的绝对路径：

```conf
watcher /path/to/kitty-im-control.py
```

3. 如果不使用 Fcitx 5，修改 watcher 顶部的输入法命令。

使用 tmux 时，启用透传：

```tmux
set -g allow-passthrough on
```

SSH 会话默认启用 Kitty 消息的 tmux 透传包装，也可以显式配置：

```lua
require("imselect").setup({
    driver = "kitty",
    kitty = {
        tmux_passthrough = true,
    },
})
```

## 文档与开发

- [自定义策略与驱动](docs/extending.md)
- [输入法状态设计](docs/input-state.md)
- [回归测试](tests/README.md)
- [演示录制与验证](demos/README.md)

## 许可证

[MIT](LICENSE)
