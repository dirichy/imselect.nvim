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

Built-in `neovide` and `kitty` drivers provide `temp_ascii`/`restore` directly. Neovide disables/re-enables IME input without saving the gate state; Kitty delegates temporary switching and restoration to its external controller. The `fcitx`, `macism`, `im_select`, and `winime` drivers use the shared state restoration mechanism.

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

内置的 `neovide` 和 `kitty` 驱动直接提供 `temp_ascii`/`restore`。Neovide 关闭／重新允许 IME 输入，不保存开关状态；Kitty 将临时切换与恢复交给外部控制器。`fcitx`、`macism`、`im_select` 和 `winime` 驱动使用公共状态恢复机制。

状态可以是布尔值或字符串，取决于底层输入法 API。

自行管理状态的驱动收到重复 ASCII 请求时，必须协调用户手动切换后的状态，不能仅因已有保存状态就忽略请求。

示例见[驱动实现](../lua/imselect/driver/)。
