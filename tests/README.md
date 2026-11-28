# Regression tests / 回归测试

Run from the repository root with Neovim:

在项目根目录使用 Neovim 运行：

```sh
for test in tests/*.lua; do
  nvim --headless -u NONE -i NONE -l "$test" || exit 1
done
```

Each file runs in a separate Neovim process with no user configuration. Tests use
mocked driver commands and Windows DLL calls, or Neovide's variables. They do not
switch the system input method or require fcitx, macism, Kitty, or Neovide to be installed.
They verify command arguments, executable discovery, initialization, strategy
configuration and selection, exact state restoration, default driver selection, custom selectors and disabling initialization, and
buffer transitions. WSL selection tests cover executable discovery and fallback, while mocked
PowerShell worker tests cover asynchronous startup, fragmented replies, latest-intent
coalescing, API errors, communication timeouts and shutdown. The command helper is also tested with real Neovim subprocesses
for synchronous/asynchronous results, failed exits, and timeouts. The Windows FFI declarations are parsed by real LuaJIT, but
native input method behavior still requires testing on the corresponding platform.

Mode tests send real `i`, Escape and command-line input to an embedded Neovim.
They verify that custom cursor inspectors run only in Insert, mode rules remain
independent, and a manual IME choice in code survives typing but is reconciled on
Escape even when the combined policy remains ASCII. Restore tests cover repeated
requests preserving the saved state and capturing a new manual non-ASCII choice.
Native completion tests cover `ic` and `ix`, preserving manual input in code and
continuing to evaluate custom cursor inspectors during completion.

每个文件都在独立 Neovim 进程中运行，不加载用户配置。驱动命令和 Windows DLL 调用
使用 mock，或通过 Neovide 变量验证，因此不会切换系统输入法，也不要求安装 fcitx、macism、Kitty 或
Neovide。测试覆盖命令参数、可执行文件查找、初始化、策略配置与选择、原状态恢复、
默认驱动选择、自定义选择函数与禁用初始化，以及缓冲区切换。WSL 测试还覆盖程序查找和回退，
并模拟 PowerShell 进程验证异步启动、分段响应、最新意图合并、API 错误、通信超时与退出清理。命令 helper 还通过真实 Neovim 子进程验证同步、异步、
非零退出和超时。Windows FFI 声明由真实 LuaJIT 解析，原生输入法的
实际行为仍需在对应平台验证。

模式测试向嵌入式 Neovim 发送真实的 `i`、Esc 和命令行输入，验证自定义光标判断仅在
Insert 中调用、模式要求独立生效，以及代码区手切输入法后继续输入不会被改回，
但按 Esc 时即使总要求仍是 ASCII，也会重新协调。恢复测试覆盖重复请求保留原
缓存，以及识别并保存新的手动非 ASCII 选择。
原生补全测试覆盖 `ic`、`ix` 子模式，验证代码区手动选择不被补全覆盖，并且补全
期间仍使用自定义光标判断。

Syntax tests use real Lua, Markdown, Markdown Inline and Vim parsers shipped with
Neovim, with highlighting disabled. They cover node and injection classification,
quote/comment boundaries, unavailable parsers, and reparsing edits. An embedded
Neovim also processes real Insert-mode input and verifies Neovide driver state on
cursor, mode and text changes; it does not require a GUI or change the system IME.

语法测试使用 Neovim 自带的真实 Lua、Markdown、Markdown Inline 和 Vim parser，
不启用高亮，覆盖节点和注入语言分类、引号和注释边界、无 parser 回退及编辑后重新
解析。另启动嵌入式 Neovim 处理真实插入模式输入，验证光标、模式和文本变化时的
Neovide 驱动状态，无需 GUI，也不会修改系统输入法。

`syntax_latex.lua` additionally requires an installed LaTeX parser. It verifies
prose, comments, inline/display math, math environments, nested text, verbatim
and listings without the removed nvimtex strategy.

`syntax_latex.lua` 还需要已安装 LaTeX parser，验证正文、注释、行内及独立公式、
数学环境、公式内文本、verbatim 和 listing，不依赖已移除的 nvimtex 策略。
