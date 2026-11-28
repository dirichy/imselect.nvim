# Extending imselect / 扩展 imselect

## English

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

Built-in `neovide`, `kitty`, and `wsl` drivers provide `temp_ascii`/`restore` directly. Neovide disables/re-enables IME input without saving the gate state; Kitty delegates temporary switching and restoration to its external controller. WSL delegates state ownership to a persistent PowerShell worker, including IME open status and conversion mode; its asynchronous transport serializes requests and keeps only the latest pending intent. The `fcitx`, `dbus`, `fcitx_macos_direct`, `macism`, `im_select`, and `winime` drivers use the shared state restoration mechanism.

The Linux `dbus` driver uses LuaJIT FFI and a private libdbus session connection.
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

内置的 `neovide`、`kitty` 和 `wsl` 驱动直接提供 `temp_ascii`/`restore`。Neovide 关闭／重新允许 IME 输入，不保存开关状态；Kitty 将临时切换与恢复交给外部控制器。WSL 由常驻 PowerShell 进程保存 IME 开关和转换状态，异步传输串行处理请求，只保留最新的待处理意图。`fcitx`、`dbus`、`fcitx_macos_direct`、`macism`、`im_select` 和 `winime` 驱动使用公共状态恢复机制。

Linux `dbus` 驱动通过 LuaJIT FFI 复用私有 libdbus 会话连接，调用 Fcitx 5
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
