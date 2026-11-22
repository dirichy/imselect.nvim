# 输入法状态设计 / Input method state design

本文记录已实现的模式与上下文协调，以及它与尚未实现的外部带 ID 请求的关系。

This document records the implemented mode/context coordination and its relationship
to external requests with IDs, which are not implemented here.

## 为什么延后处理 / Why defer handling

自动判断可能出错。如果用户手动选择了输入法，每次输入都重新执行自动判断的
结果，就会不断把用户切回错误状态。另一方面，每次光标移动都进行完整的语法
判断和输入法状态查询也有成本。因此，手动选择需要在当前上下文中得到保留，
判断和执行应在需要重新应用规则的边界进行，而不是逐次输入、逐次移动都强制同步。
这里是设计动机，不是性能测量结论，也不表示当前实现已经避免了所有逐次判断。

Automatic classification can be wrong. Reapplying its result on every input would
repeatedly undo the user's manual correction. Full syntax classification and input
method queries on every cursor movement also have a cost. Manual choices should
therefore survive within the current context, with rules reapplied at the relevant
boundaries rather than forced on every input or movement. These are design motives,
not benchmark results or a claim that the implementation already avoids all such checks.

## 两个逻辑步骤 / Two logical steps

延后处理在语义上仍然包含两个步骤：

1. 处理用户手动切换与光标移动：结合实际输入法、用户选择和光标上下文，确定
   当前编辑上下文的输入意图，避免在同一上下文中反复覆盖用户手动选择。
2. 处理模式切换：在模式边界应用目标模式的要求，例如进入 Normal 时要求 ASCII。
   前一步允许的手动中文，不会因此取消 Normal 的 ASCII 要求。

实现可以把这两个步骤合并为一次处理，但结果必须与依次处理两步等价。
这不要求实际切换两次输入法；可以只执行最终需要的操作。不能仅比较前后策略
返回值是否相同，就省略模式边界的处理。

Deferred handling still has two logical steps:

1. Handle manual changes and cursor movement: reconcile the actual input method,
   the user's choice and cursor context to determine the editing context's input
   intent, preserving manual corrections within that context.
2. Handle mode changes: apply the target mode's requirements at the boundary.
   For example, entering Normal requires ASCII even if the previous step allowed
   a manual choice of Chinese input.

An implementation may combine these steps, provided the result is equivalent to
processing both in order. It need not physically switch the input method twice;
only the final operation may be needed. Equal policy results before and after a
transition are insufficient grounds for skipping the mode boundary.

例如，代码块中 Insert 和 Normal 的自动判断都要求 ASCII。用户在 Insert 手动
切成中文后按 Esc，虽然自动判断仍是 ASCII，实际输入法却已经改变。进入 Normal
必须重新落实 ASCII 要求。仅按策略结果去重会漏掉这次切换，不能视为延后处理
的预期行为。

For example, both Insert in a code block and Normal select ASCII automatically.
If the user manually selects Chinese in Insert and presses Escape, the automatic
decision remains ASCII but the actual input method has changed. Entering Normal
must reassert ASCII. Deduplicating solely by the policy result misses this change;
that is not the intended behavior of deferred handling.

## 模式与总要求缓存 / Cached mode and combined requirements

主流程分别保存模式是否要求 ASCII，以及合并后的总要求。Insert 的模式本身不
要求 ASCII，改由当前缓冲区选中的策略判断光标上下文；搜索允许恢复；其余模式
要求 ASCII。自定义策略和默认策略遵守同一边界，只在 Insert 中参与判断，仍按
现有优先级选择一个策略，不引入多个同时生效的策略。

Insert 包含 `ic`（补全）和 `ix`（CTRL-X）等子模式，按 mode 的 `i` 前缀识别。
这些子模式仍使用光标上下文要求，彼此切换不会激活模式的 ASCII 要求；否则每次
输入触发补全时都会错误地覆盖手动选择。

总要求变化时协调输入法；总要求不变、但模式从不要求 ASCII 变为要求 ASCII
时，也重新协调。其余相同结果继续去重。语义上是两个要求来源，实现上只是两个
缓存，对外仍为同一个 Neovim 控制者，不引入请求集合。

协调时沿用驱动的手切处理路径，不绕过它直接切换系统状态。Kitty 继续发送原有
请求，由 watcher 的 `sync_user_change()` 先同步手切状态再应用要求。通用状态
驱动的重复 ASCII 请求会查询实际状态：若仍是 ASCII，保留原恢复缓存；若已手切
为非 ASCII，更新恢复缓存后临时切回 ASCII。这里不监听每次系统输入法切换。

The core caches whether the mode requires ASCII separately from the combined
requirement. Insert delegates cursor classification to the selected buffer strategy;
search permits restoration; other modes require ASCII. Default and custom strategies
run only in Insert, using the existing priority selection rather than simultaneous
strategies.

Insert includes completion submodes such as `ic` and `ix` (CTRL-X), identified by
the `i` prefix. They continue to use the cursor context requirement. Transitions
between them do not activate the mode's ASCII requirement; otherwise completion
triggered by typing would incorrectly override manual input choices.

Input is reconciled when the combined requirement changes, or when the mode starts
requiring ASCII despite an unchanged combined result. Other equal results remain
deduplicated. These are two logical sources represented by two caches, with one
external Neovim controller and no request set.

Reconciliation follows the driver's manual-change handling instead of bypassing it.
Kitty keeps its existing messages; the watcher runs `sync_user_change()` before
applying the requirement. Repeated ASCII requests to state-based drivers query the
actual state: ASCII preserves the existing restoration cache; a manual non-ASCII
choice updates that cache before temporarily selecting ASCII again. This does not
listen to every system input-method change.

## 与带 ID 请求的关系 / Relationship to requests with IDs

两步处理决定控制端何时发出什么请求；ID 用于接收端协调多个控制者的请求。
两者职责独立，延后处理不改变带 ID 请求的语义。

外部协调器可采用的规则是：`temp_ascii(id)` 登记该控制者的 ASCII 请求，`restore(id)`
只撤销对应请求；只要还有控制者要求 ASCII，就不执行恢复，全部请求撤销后才恢复。
同一 ID 重复请求不累计，但请求已经存在不代表实际输入法仍是 ASCII；模式边界
重新发来的请求仍需能够落实 ASCII 要求。

模式和光标上下文可以分别参与决策，也可以合并处理；是否合并不决定 ID 如何
划分，也不改变“全部控制者释放后才恢复”的规则。ID 的生命周期、退出清理和
恢复状态的保存方式仍需在实现前明确。跨程序协调应由外部脚本或服务负责，例如
调用真实 `fcitx5-remote` 的 wrapper，不由 Neovim 内部处理 IPC。

The two steps determine when and what a controller requests. IDs let the receiver
coordinate requests from multiple controllers. Deferred handling does not change
the semantics of requests with IDs.

The proposed rule is: `temp_ascii(id)` registers a controller's ASCII request, and
`restore(id)` withdraws only that request. Restoration occurs only when no
controller still requests ASCII. Repeated requests from one ID do not accumulate,
but an existing request does not prove that the actual input method is still ASCII.
A renewed request at a mode boundary must still be able to enforce ASCII.

Mode and cursor context may contribute separately or be processed together. Combining
them neither determines ID allocation nor changes the rule that restoration waits
for all controllers to release their requests. ID lifetime, exit cleanup and saved
restoration state still need to be specified before implementation. Cross-program
coordination belongs in an external script or service, such as a wrapper around
the real `fcitx5-remote`, rather than IPC inside Neovim.
