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
configuration and selection, exact state restoration, driver precedence, and
buffer transitions. The command helper is also tested with real Neovim subprocesses
for synchronous/asynchronous results, failed exits, and timeouts. The Windows FFI declarations are parsed by real LuaJIT, but
native input method behavior still requires testing on the corresponding platform.

每个文件都在独立 Neovim 进程中运行，不加载用户配置。驱动命令和 Windows DLL 调用
使用 mock，或通过 Neovide 变量验证，因此不会切换系统输入法，也不要求安装 fcitx、macism、Kitty 或
Neovide。测试覆盖命令参数、可执行文件查找、初始化、策略配置与选择、原状态恢复、
驱动优先级，以及缓冲区切换。命令 helper 还通过真实 Neovim 子进程验证同步、异步、
非零退出和超时。Windows FFI 声明由真实 LuaJIT 解析，原生输入法的
实际行为仍需在对应平台验证。
