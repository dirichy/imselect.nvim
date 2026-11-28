param(
    [ValidateSet('im_select', 'winime', 'wsl')][string]$Driver,
    [ValidateSet('prepare', 'get')][string]$Action
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class NativeInput {
    [StructLayout(LayoutKind.Sequential)]
    struct GUIINFO {
        public uint size, flags;
        public IntPtr active, focus, capture, menu, move, caret;
        public int left, top, right, bottom;
    }
    [DllImport("user32.dll")] static extern bool GetGUIThreadInfo(uint thread, ref GUIINFO info);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr window, IntPtr process);
    [DllImport("user32.dll")] static extern IntPtr GetKeyboardLayout(uint thread);
    [DllImport("imm32.dll")] static extern IntPtr ImmGetDefaultIMEWnd(IntPtr window);
    [DllImport("user32.dll")] static extern IntPtr SendMessageTimeoutW(IntPtr window,
        uint message, UIntPtr command, IntPtr value, uint flags, uint timeout, out UIntPtr result);
    public static IntPtr Focus() {
        GUIINFO info = new GUIINFO();
        info.size = (uint)Marshal.SizeOf(info);
        if (!GetGUIThreadInfo(0, ref info)) throw new Exception("No interactive foreground session");
        IntPtr window = info.focus != IntPtr.Zero ? info.focus : info.active;
        if (window == IntPtr.Zero) throw new Exception("No foreground input window");
        return window;
    }
    public static long Message(IntPtr window, uint message, uint command, IntPtr value) {
        UIntPtr result;
        if (SendMessageTimeoutW(window, message, new UIntPtr(command), value, 0x22, 500, out result) == IntPtr.Zero)
            throw new Exception("Windows input message failed");
        return unchecked((long)result.ToUInt64());
    }
    public static IntPtr IME(IntPtr window) {
        IntPtr ime = ImmGetDefaultIMEWnd(window);
        if (ime == IntPtr.Zero) throw new Exception("Foreground terminal has no IME window");
        return ime;
    }
    public static int Layout(IntPtr window) {
        return (int)(GetKeyboardLayout(GetWindowThreadProcessId(window, IntPtr.Zero)).ToInt64() & 0xffff);
    }
}
'@
$window = [NativeInput]::Focus()
if ($Action -eq 'prepare') {
    $chinese = [System.Windows.Forms.InputLanguage]::InstalledInputLanguages |
        Where-Object { $_.Culture.Name -eq 'zh-CN' } | Select-Object -First 1
    if (-not $chinese) { throw 'Install the Simplified Chinese keyboard before running native driver tests' }
    [void][NativeInput]::Message($window, 0x0050, 0, $chinese.Handle)
    if ([NativeInput]::Layout($window) -ne 2052) { throw 'Foreground terminal did not select the Chinese keyboard' }
    if ($Driver -ne 'im_select') {
        $ime = [NativeInput]::IME($window)
        [void][NativeInput]::Message($ime, 0x0283, 6, [IntPtr]1)
        [void][NativeInput]::Message($ime, 0x0283, 2, [IntPtr]1)
        if ([NativeInput]::Message($ime, 0x0283, 5, [IntPtr]::Zero) -eq 0 -or
            ([NativeInput]::Message($ime, 0x0283, 1, [IntPtr]::Zero) -band 1) -eq 0) {
            throw 'The real terminal IME did not enter Chinese input mode'
        }
    }
}
if ($Driver -eq 'im_select') {
    [Console]::WriteLine([NativeInput]::Layout($window))
} else {
    $ime = [NativeInput]::IME($window)
    $open = [NativeInput]::Message($ime, 0x0283, 5, [IntPtr]::Zero)
    if ($Driver -eq 'winime') {
        [Console]::WriteLine(($open -ne 0).ToString().ToLowerInvariant())
    } else {
        $conversion = [NativeInput]::Message($ime, 0x0283, 1, [IntPtr]::Zero)
        [Console]::WriteLine("${open}:${conversion}")
    }
}
