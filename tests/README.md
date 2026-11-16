# Regression tests / 回归测试

Run from the repository root with Neovim:

在项目根目录使用 Neovim 运行：

```sh
for test in tests/*.lua; do
  nvim --headless -u NONE -i NONE -l "$test" || exit 1
done
```

Each file runs in a separate Neovim process with no user configuration. Driver
commands are mocked or use Neovide's variables, so these tests do not switch the
system input method or require fcitx, macism, Kitty, or Neovide to be installed.
They verify command arguments, executable discovery, initialization, strategy
configuration and selection, driver precedence, and buffer transitions. Native
input method behavior still requires testing on the corresponding platform.

每个文件都在独立 Neovim 进程中运行，不加载用户配置。驱动命令使用 mock，或通过
Neovide 变量验证，因此不会切换系统输入法，也不要求安装 fcitx、macism、Kitty 或
Neovide。测试覆盖命令参数、可执行文件查找、初始化、策略配置与选择、驱动优先级，
以及缓冲区切换。原生输入法的实际行为仍需在对应平台验证。
