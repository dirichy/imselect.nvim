# imselect.nvim

[English](README.md) · [简体中文](README.zh-CN.md)

**专心写代码、注释和公式，让 Neovim 帮你切换输入法。**

普通模式需要英文，注释需要中文，LaTeX 正文和公式之间又要来回切换——有时还没按一次 Escape，就已经切了好几轮。

imselect 同时关注你的编辑模式和**正在编辑的内容**：代码和公式自动使用 ASCII，正文恢复原来的输入法；上下文不变时，保留你的手动选择。

![连续编辑 LaTeX，手动切换输入法 0 次](https://github.com/dirichy/imselect.nvim/releases/download/demos/demo-zh.gif)

*中文正文 → 公式 → 正文 → `\text{...}` 中的中文 → 求和公式。全程保持 Insert 模式，**手动切换输入法 0 次**。使用真实 fcitx5-rime 输入，配合 Neovim 原生 snippet 展开公式、跳转字段。*

[高清视频](https://github.com/dirichy/imselect.nvim/releases/download/demos/demo-zh.mp4) · [复现全部演示](demos/README.md)

## 从按 Escape 切英文，到整个编辑过程

模式切换只是起点，日常编辑中的这些细节也都照顾到了：

| 当你…… | imselect 会…… |
| --- | --- |
| 在代码、字符串和注释之间移动 | 跟随语法边界切换，即使一直处于 Insert 模式 |
| 跳入公式或公式的 `\text{...}` 字段 | 根据新上下文切换，也支持 snippet 字段跳转 |
| 用 `/` 或 `?` 搜索，再执行 `:` 命令 | 搜索时恢复输入法，命令中保持 ASCII |
| 在代码中手动切换输入法 | 上下文分类不变时保留你的选择 |
| 打开或关闭插入补全（`ic` / `ix`） | 继续沿用 Insert 模式的判断规则 |
| 手动切换后按 Escape | 重新落实 ASCII 要求，即使之前就在代码区 |
| 从需要 ASCII 的区域返回正文 | 恢复驱动保存的输入状态，无需写死中文输入源 |
| 在 Kitty 中通过 SSH 编辑 | 通过本地 watcher 控制本机输入法 |

Tree-sitter 判断上下文，驱动负责控制输入法。无需为每种语言配置切换快捷键，也不依赖轮询或 snippet 插件。没有可用的 parser 时，仍可按模式切换。

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

恢复时使用驱动保存的输入状态，无需预先指定一个固定的“中文输入法”。

### 按语法切换

写中文字符串、添加注释、用 ASCII 输入计算式，再追加中文行尾注释：

![Lua 代码与中文字符串、注释混合编辑](https://github.com/dirichy/imselect.nvim/releases/download/demos/code-zh.gif)

*字符串和注释中真实组词输入中文，`local total = 6 * 7` 使用 ASCII。在代码行尾输入 `-- `，也会自动恢复中文输入。**手动切换输入法 0 次。*** [高清视频](https://github.com/dirichy/imselect.nvim/releases/download/demos/code-zh.mp4)

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

注入语言独立判断。例如，Markdown 中的 Lua 代码块使用 ASCII，其中的注释仍可使用中文输入法。

移动光标或编辑文本即可触发切换，无需退出 Insert 模式。

行为取决于 parser 当前的语法树，包括尚未完成的语法。未识别的节点继承最近的已分类祖先；没有匹配分类时使用 ASCII。支持的节点类型见[分类规则](lua/imselect/syntax.lua)。

### 自动切换，也尊重手动选择

自动切换应该帮助你，而不是反复覆盖你的选择。

例如，在代码区编辑时：

1. imselect 临时切换为 ASCII。
2. 你手动切换到其他输入法。
3. 继续输入、移动光标或使用补全。
4. 只要上下文分类不变，插件就保留你的选择。
5. 按 Escape 后，imselect 再次切换为 ASCII。

代码区和 Normal 模式通常都要求 ASCII，但进入 Normal 模式时仍会重新落实这一要求。

补全子模式（`ic` 和 `ix`）属于 Insert 模式。打开或关闭补全菜单，本身不会覆盖你的输入法选择。

### 只在必要时协调输入状态

imselect 在编辑要求变化时响应，不会持续强制输入法保持某个状态。

插件会判断当前编辑上下文；要求不变时，除需要重新协调的边界外，不会查询或修改输入法状态。

这样既减少了不必要的驱动调用，也让手动选择自然保留。

状态协调模型和回归覆盖见[输入法状态设计](docs/input-state.md)。

## 支持的驱动

| 驱动 | 适用环境 | 依赖 |
| --- | --- | --- |
| `fcitx` | Linux、macOS | Fcitx 4 或 Fcitx 5 |
| `macism` | macOS | `macism` 可执行文件 |
| `neovide` | Neovide | 无 |
| `kitty` | 本地或远程 Kitty 会话 | 本地 Kitty watcher |
| `im_select` | Windows | `im-select.exe` |
| `winime` | Windows | 带 LuaJIT 的原生 Windows Neovim |

### 自动选择驱动

默认按以下顺序选择：

- Neovide 会话：`neovide`
- SSH 会话：`kitty`
- Linux：`fcitx`
- macOS：`fcitx`，其次 `macism`
- Windows：`im_select`，其次 `winime`

依赖外部命令的驱动会检查命令是否可用。系统不受支持，或 Linux/macOS 上没有找到合适的可执行文件时，跳过初始化。

命令检测不会确认对应输入法是否正在运行。SSH 检测默认你已配置本地 Kitty watcher，不会检测终端类型。

## 配置

默认配置尽量做到开箱即用。

```lua
require("imselect").setup({
    -- 默认自动选择驱动。
    -- 指定驱动名称可覆盖自动检测。
    -- 设为 false 则跳过初始化。
    driver = "fcitx",

    -- 启用后，在 FocusLost 时恢复输入法，在 FocusGained 时重新协调状态。
    focus_event = false,
})
```

省略 `driver` 即可使用自动检测。

### 自定义驱动选择

`driver` 也可以是函数，接收合并后的配置，在 setup 时调用一次。

返回驱动名称即可启用；返回 `false` 或 `nil` 则跳过初始化。

例如，在 SSH 中禁用 imselect，本地 macOS 会话使用 macism：

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

各驱动的专用选项放在对应模块名下。

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

驱动会记住之前的输入源 ID，并在需要时恢复。

### Windows

`im_select` 驱动需要 [im-select.exe](https://github.com/daipeihust/im-select)。

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

它通过 LuaJIT FFI 控制前台窗口的 IME 开关，无需 AutoHotkey 或外部可执行文件。

**注意：** 两个 Windows 驱动都仍需原生 Windows 实机测试。

### Kitty 与 SSH

即使 Neovim 运行在远程服务器上，imselect 也能控制本机输入法。

Kitty 驱动通过终端连接发送 OSC 用户变量消息；本地 watcher 接收请求并管理输入法。

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

远程 Neovim 无需直接连接本机输入法服务。

## 扩展 imselect

输入法控制与编辑上下文判断相互独立。

- **驱动（driver）** 决定如何控制输入法。
- **策略（strategy）** 决定当前 Insert 上下文应使用 ASCII，还是恢复输入法。

### 自定义策略

覆盖默认的光标上下文判断函数：

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

判断函数接收缓冲区编号，返回：

- `true`：恢复保存的输入状态。
- `false`：临时切换为 ASCII。

判断函数只在 Insert 模式（含补全子模式）中求值。模式自身的要求由核心独立处理。

### 自定义驱动

驱动模块导出 `setup(opts)`，返回基于状态的驱动：

```lua
{
    ascii_state = ...,
    get_state = function() ... end,
    set_state = function(state) ... end,
}
```

或返回自行管理临时输入状态的驱动：

```lua
{
    temp_ascii = function() ... end,
    restore = function() ... end,
}
```

基于状态的驱动会自动接入公共状态恢复机制。

状态可以是布尔值或字符串，取决于底层输入法 API。

自行管理状态的驱动收到重复 ASCII 请求时，必须协调用户手动切换后的状态，不能仅因已有保存状态就忽略请求。

示例见[驱动实现](lua/imselect/driver/)。

## 文档与开发

- [输入法状态设计](docs/input-state.md)
- [回归测试](tests/README.md)
- [演示录制与验证](demos/README.md)

## 许可证

[MIT](LICENSE)
