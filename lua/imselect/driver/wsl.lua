local M = {}
local util = require("imselect.util")

function M.find_command(opts)
	if opts.command then
		return util.find_executable({ opts.command })
	end
	return util.find_executable({
		"powershell.exe",
		"/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe",
	})
end

-- The Windows worker owns the saved state, including the conversion mode.
local script = [=[
$ErrorActionPreference = 'Stop'
try {
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class Imselect {
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("imm32.dll")] static extern IntPtr ImmGetDefaultIMEWnd(IntPtr window);
    [DllImport("user32.dll", SetLastError = true)]
    static extern IntPtr SendMessageTimeoutW(IntPtr window, uint message,
        UIntPtr command, IntPtr value, uint flags, uint timeout, out UIntPtr result);
    static int[] saved;
    static int Control(IntPtr window, uint command, int value) {
        UIntPtr result;
        if (SendMessageTimeoutW(window, 0x0283, new UIntPtr(command),
                new IntPtr(value), 0x0022, 100, out result) == IntPtr.Zero)
            throw new InvalidOperationException("IME control failed or timed out");
        return unchecked((int)result.ToUInt64());
    }
    public static void Apply(string operation) {
        if (operation == "restore" && saved == null) return;
        IntPtr foreground = GetForegroundWindow();
        if (foreground == IntPtr.Zero)
            throw new InvalidOperationException("No foreground window");
        IntPtr window = ImmGetDefaultIMEWnd(foreground);
        if (window == IntPtr.Zero)
            throw new InvalidOperationException("No foreground IME window");
        if (operation == "temp_ascii") {
            int open = Control(window, 5, 0);
            int conversion = Control(window, 1, 0);
            if (saved == null || open != 0 || conversion != 0)
                saved = new int[] { open, conversion };
            if (open != 0) Control(window, 6, 0);
            if (conversion != 0) Control(window, 2, 0);
        } else if (operation == "restore") {
            Control(window, 6, saved[0]);
            Control(window, 2, saved[1]);
            saved = null;
        } else {
            throw new InvalidOperationException("Unknown operation");
        }
    }
}
'@
[Console]::Out.WriteLine('READY')
while ($null -ne ($operation = [Console]::In.ReadLine())) {
    try {
        [Imselect]::Apply($operation)
        [Console]::Out.WriteLine('OK')
    } catch {
        [Console]::Out.WriteLine('ERROR ' + ($_.Exception.Message -replace '[\r\n]', ' '))
    }
}
} catch {
    [Console]::Out.WriteLine('ERROR ' + ($_.Exception.Message -replace '[\r\n]', ' '))
    exit 1
}
]=]

M.setup = util.once(function(opts)
	local command = M.find_command(opts)
	local job, timer
	local ready, busy, stopped = false, false, false
	local pending, warned
	local fragment = ""

	local function cancel_timer()
		if timer and not timer:is_closing() then
			timer:stop()
			timer:close()
		end
		timer = nil
	end

	local function report(message)
		if not warned then
			warned = true
			vim.schedule(function()
				vim.notify("imselect: WSL PowerShell: " .. message, vim.log.levels.WARN)
			end)
		end
	end

	local function stop(message)
		if stopped then
			return
		end
		stopped = true
		cancel_timer()
		if job and job > 0 then
			vim.fn.jobstop(job)
		end
		if message then
			report(message)
		end
	end

	local function deadline(ms)
		cancel_timer()
		timer = vim.defer_fn(function()
			stop(ready and "request timed out" or "startup timed out")
		end, ms)
	end

	local function flush()
		if stopped or not ready or busy or not pending then
			return
		end
		local operation = pending
		pending, busy = nil, true
		deadline(1000)
		local ok, sent = pcall(vim.fn.chansend, job, operation .. "\n")
		if not ok or sent <= 0 then
			stop("cannot send request")
		end
	end

	local function receive(line)
		if stopped then
			return
		end
		line = line:gsub("\r$", "")
		if not ready then
			if line == "READY" then
				ready = true
				cancel_timer()
				flush()
			elseif line:sub(1, 6) == "ERROR " then
				stop(line:sub(7))
			end
		elseif busy and (line == "OK" or line:sub(1, 6) == "ERROR ") then
			busy = false
			cancel_timer()
			if line == "OK" then
				warned = false
			else
				report(line:sub(7))
			end
			flush()
		end
	end

	-- A command string avoids PowerShell's interactive stdin parser and prompts.
	job = vim.fn.jobstart({ command, "-NoLogo", "-NoProfile", "-NonInteractive", "-Command", script }, {
		stdin = "pipe",
		on_stdout = function(_, lines)
			for i, line in ipairs(lines) do
				fragment = fragment .. line
				if i < #lines then
					receive(fragment)
					fragment = ""
				end
			end
		end,
		on_exit = function()
			job = nil
			stop("worker exited")
		end,
	})
	if job <= 0 then
		stop("cannot start worker")
	else
		deadline(10000)
	end

	M.temp_ascii = function()
		pending = "temp_ascii"
		flush()
	end
	M.restore = function()
		pending = "restore"
		flush()
	end
	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = function()
			stop()
		end,
	})
	return M
end)

return M
