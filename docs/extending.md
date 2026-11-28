# Extending imselect / 扩展 imselect

## English

Input method control and editing-context classification are independent.

- A **driver** determines how to control the input method.
- An **inspector** determines when the current Insert-mode context should use ASCII or restore input.

### Custom inspectors

Override the default cursor inspector:

```lua
require("imselect").setup({
    inspector = function(bufnr)
        return vim.bo[bufnr].filetype == "text"
    end,
})
```

The inspector receives the buffer number and returns:

- `true`: restore the saved input state.
- `false`: temporarily select ASCII.

Inspectors are evaluated only in Insert mode, including completion submodes. Mode requirements are handled independently by the core.

`require("imselect").set_inspector(fn, opts)` registers or replaces an inspector:

| `opts` | Scope |
| --- | --- |
| Omitted or `{}` | Global |
| `{ filetype = "lua" }` | Exact buffer filetype |
| `{ filetype = { "text", "markdown" } }` | Each listed filetype |
| `{ buffer = true }` or `{ buffer = 0 }` | Current buffer |
| `{ buffer = bufnr }` | Specified valid buffer |

`buffer` and `filetype` are mutually exclusive; `buffer = false` leaves buffer
scope unselected. The most specific registered inspector wins:
**buffer > filetype > global > built-in syntax detection**. Only that function is
called; `false` means ASCII, not fallback to another inspector. Filetype matching
uses the exact `vim.bo[bufnr].filetype`, including compound filetypes.

Pass `nil` instead of a function to remove the override at that scope. Removing
the global override restores built-in syntax detection. Registration works before
or after `setup()`; an explicit `setup({ inspector = fn })` sets the global
override without changing filetype or buffer registrations. Changes take effect
on the next update; use `require("imselect").update()` to apply immediately after
initialization.

The inspector module owns all registrations and a single `BufWipeout` cleanup
autocmd. Buffer overrides survive unload, `:bdelete`, and filetype changes, and
release their function references when the buffer is wiped. Inspectors are
resolved on each inspection, so changing an override or filetype needs no cache
invalidation. Storage uses Lua tables, matching pairwise's buffer lifecycle.

Migration: the former `strategy`, `strategy_provider`, and `add_strategy` APIs have
been removed. Replace `strategy.strategy_provider.default.inspecter` with the
top-level `inspector` setup option, and `set_inspecter(bufnr, fn)` with
`set_inspector(fn, { buffer = bufnr })`. Replace filetype-based `condition` and
`priority` selection with scoped registrations; move cursor-dependent decisions
into the inspector itself. For one scope, the last registration replaces the
previous one.

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

Built-in `neovide`, `kitty`, and `wsl` drivers provide `temp_ascii`/`restore` directly. Neovide disables/re-enables IME input without saving the gate state; Kitty delegates temporary switching and restoration to its external controller. WSL delegates state ownership to a persistent PowerShell worker, including IME open status and conversion mode; its asynchronous transport serializes requests and keeps only the latest pending intent. The `fcitx`, `fcitx_dbus`, `fcitx_macos_direct`, `macism`, `im_select`, and `winime` drivers use the shared state restoration mechanism.

The Linux `fcitx_dbus` driver uses LuaJIT FFI and a private libdbus session connection.
It calls Fcitx 5 Controller1 `State`/`Activate`/`Deactivate`, matching `fcitx5-remote`.
The driver owns connection cleanup and reconnects after a bus disconnect on the next call;
Fcitx restarts use the same well-known service name. Errors propagate to the caller,
and synchronous calls have a 1000 ms reply timeout. No event-loop integration or
state cache is needed.

The experimental `fcitx_macos_direct` driver mirrors the macOS wrappers: Carbon checks for an input
source ID prefixed with `org.fcitx.inputmethod.Fcitx5.`, while libcurl sends empty
POST requests to `/remote/`, `/remote/c`, and `/remote/o`. It preserves the wrappers'
boolean active-state semantics, including reporting false when another system
source is selected. It does not select Fcitx as a system input source. The driver
owns its libcurl handle and callback, which are released together by the FFI
finalizer. Requests bypass proxy settings, validate HTTP status and state values,
and use a one-second total timeout. The request function has JIT disabled because
libcurl calls back into Lua. Beast currently disables HTTP keep-alive.

States may be booleans or strings, depending on the underlying input method API.

Direct drivers must reconcile manual input method changes on repeated ASCII requests, rather than simply ignoring requests when a saved state already exists.

See the [driver implementations](../lua/imselect/driver/) for examples.

## 简体中文

输入法控制与编辑上下文判断相互独立。

- **驱动（driver）** 决定如何控制输入法。
- **判断函数（inspector）** 决定当前 Insert 上下文应使用 ASCII，还是恢复输入法。

### 自定义 inspector

覆盖默认的光标上下文判断函数：

```lua
require("imselect").setup({
    inspector = function(bufnr)
        return vim.bo[bufnr].filetype == "text"
    end,
})
```

判断函数接收缓冲区编号，返回：

- `true`：恢复保存的输入状态。
- `false`：临时切换为 ASCII。

判断函数只在 Insert 模式（含补全子模式）中求值。模式自身的要求由核心独立处理。

通过 `require("imselect").set_inspector(fn, opts)` 注册或替换判断函数：

| `opts` | 作用域 |
| --- | --- |
| 省略或 `{}` | 全局 |
| `{ filetype = "lua" }` | 精确匹配 buffer 的 filetype |
| `{ filetype = { "text", "markdown" } }` | 列出的每个 filetype |
| `{ buffer = true }` 或 `{ buffer = 0 }` | 当前 buffer |
| `{ buffer = bufnr }` | 指定的有效 buffer |

`buffer` 与 `filetype` 互斥；`buffer = false` 表示不选择 buffer 作用域。
按 **buffer > filetype > global > 内置语法判断** 选择最具体的已注册函数，
每次只调用一个函数；返回 `false` 表示使用 ASCII，不会继续回退。
Filetype 按 `vim.bo[bufnr].filetype` 精确匹配，复合 filetype 也按完整名称匹配。

传入 `nil` 移除对应作用域的覆盖；移除全局覆盖后恢复内置语法判断。
可在 `setup()` 前后注册；显式 `setup({ inspector = fn })` 设置全局覆盖，
保留已注册的 filetype 和 buffer 覆盖。修改在下次更新时生效；初始化后可调用
`require("imselect").update()` 立即应用。

Inspector 模块统一持有注册表和一个 `BufWipeout` 清理 autocmd。
Buffer 覆盖在卸载、`:bdelete` 或 filetype 改变后仍保留，wipe 时释放函数引用。
每次判断直接解析三层作用域，因此修改注册或 filetype 无需缓存失效逻辑。
使用 Lua 表存储，与 pairwise 的 buffer 生命周期一致。

迁移：原 `strategy`、`strategy_provider` 和 `add_strategy` API 已移除。
将 `strategy.strategy_provider.default.inspecter` 改为顶层 `inspector` 配置，
将 `set_inspecter(bufnr, fn)` 改为 `set_inspector(fn, { buffer = bufnr })`。
基于 filetype 的 `condition` 和 `priority` 改用作用域注册；依赖光标上下文的判断
放进 inspector 函数。同一作用域后注册的函数替换前一个。

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

内置的 `neovide`、`kitty` 和 `wsl` 驱动直接提供 `temp_ascii`/`restore`。Neovide 关闭／重新允许 IME 输入，不保存开关状态；Kitty 将临时切换与恢复交给外部控制器。WSL 由常驻 PowerShell 进程保存 IME 开关和转换状态，异步传输串行处理请求，只保留最新的待处理意图。`fcitx`、`fcitx_dbus`、`fcitx_macos_direct`、`macism`、`im_select` 和 `winime` 驱动使用公共状态恢复机制。

Linux `fcitx_dbus` 驱动通过 LuaJIT FFI 复用私有 libdbus 会话连接，调用 Fcitx 5
Controller1 的 `State`／`Activate`／`Deactivate`，与 `fcitx5-remote` 语义一致。
连接由驱动清理；总线断开后在下次调用时重连，Fcitx 重启通过固定服务名重新定位。
错误向调用方传播，同步调用等待回复的超时为 1000 ms，无需接入事件循环或缓存状态。

实验性 `fcitx_macos_direct` 驱动保留 macOS wrapper 的语义：Carbon 检查系统输入源 ID 是否以
`org.fcitx.inputmethod.Fcitx5.` 开头，libcurl 向 `/remote/`、`/remote/c`、
`/remote/o` 发送空 POST 请求。其他系统输入源被选中时返回 false；不会自行将
系统输入源切回 Fcitx。libcurl 句柄及回调归驱动所有，由同一个 FFI finalizer 释放。
请求绕过代理、验证 HTTP 状态和输入法状态，总超时为 1 秒。由于 libcurl 回调
会进入 Lua，请求函数关闭 JIT。Beast 当前关闭 HTTP keep-alive。

状态可以是布尔值或字符串，取决于底层输入法 API。

自行管理状态的驱动收到重复 ASCII 请求时，必须协调用户手动切换后的状态，不能仅因已有保存状态就忽略请求。

示例见[驱动实现](../lua/imselect/driver/)。
