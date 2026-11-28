vim.opt.rtp:prepend(vim.fn.getcwd())

local callbacks, sent, timers, notices, stopped
local spawn_result, send_failure
rawset(vim.fn, "executable", function(command)
	return command == "powershell.exe" and 1 or 0
end)
rawset(vim.fn, "jobstart", function(args, opts)
	assert(args[1] == "powershell.exe" and args[5] == "-Command")
	assert(opts.stdin == "pipe")
	callbacks = opts
	return spawn_result
end)
rawset(vim.fn, "chansend", function(job, value)
	assert(job == 42)
	if send_failure then
		error("closed pipe")
	end
	sent[#sent + 1] = value
	return #value
end)
rawset(vim.fn, "jobstop", function(job)
	assert(job == 42)
	stopped = stopped + 1
end)
rawset(vim, "notify", function(message)
	notices[#notices + 1] = message
end)
rawset(vim, "defer_fn", function(callback, ms)
	local timer = { callback = callback, ms = ms, closed = false }
	function timer:stop() end
	function timer:close()
		assert(not self.closed, "timer must not be closed twice")
		self.closed = true
	end
	function timer:is_closing()
		return self.closed
	end
	timers[#timers + 1] = timer
	return timer
end)

local function setup()
	vim.api.nvim_clear_autocmds({})
	package.loaded["imselect.driver.wsl"] = nil
	sent, timers, notices, stopped = {}, {}, {}, 0
	spawn_result, send_failure = 42, false
	return require("imselect.driver.wsl")
end

local function output(lines)
	callbacks.on_stdout(42, lines)
end

local function notifications()
	vim.wait(20, function()
		return false
	end)
	return #notices
end

local driver = setup().setup({})
assert(timers[1].ms == 10000)
driver.temp_ascii()
driver.restore()
assert(#sent == 0, "startup must not block or send requests before readiness")
output({ "RE" })
output({ "ADY\r", "" })
assert(vim.deep_equal(sent, { "restore\n" }), "startup keeps only the latest intent")
assert(timers[1].closed and timers[2].ms == 1000)
driver.temp_ascii()
driver.restore()
driver.temp_ascii()
assert(#sent == 1, "only one request may be in flight")
output({ "OK\r", "" })
assert(vim.deep_equal(sent, { "restore\n", "temp_ascii\n" }))
output({ "OK", "" })
driver.restore()
output({ "ERROR IME unavailable", "" })
assert(notifications() == 1 and stopped == 0, "API failure keeps the worker alive for retries")
driver.restore()
output({ "ERROR IME unavailable", "" })
assert(notifications() == 1, "repeated failures must not flood notifications")
driver.restore()
output({ "OK", "" })
driver.temp_ascii()
output({ "ERROR IME unavailable", "" })
assert(notifications() == 2, "a success resets error suppression")
vim.api.nvim_exec_autocmds("VimLeavePre", {})
assert(stopped == 1)
driver.restore()
assert(sent[#sent] == "temp_ascii\n", "shutdown must not send more operations")
callbacks.on_exit()
assert(notifications() == 2, "normal shutdown must not report a worker failure")

driver = setup().setup({})
driver.temp_ascii()
output({ "ERROR Add-Type failed", "" })
assert(stopped == 1 and #sent == 0 and notifications() == 1)
output({ "READY", "" })
assert(#sent == 0, "a failed worker must not resume")

driver = setup().setup({})
driver.temp_ascii()
timers[1].closed = true -- vim.defer_fn closes its timer before invoking the callback.
timers[1].callback()
assert(stopped == 1 and notifications() == 1)

driver = setup().setup({})
output({ "READY", "" })
driver.temp_ascii()
timers[#timers].callback()
output({ "OK", "" })
driver.restore()
assert(stopped == 1 and #sent == 1 and notifications() == 1, "late replies cannot revive a timed-out worker")

driver = setup().setup({})
output({ "READY", "" })
send_failure = true
driver.temp_ascii()
assert(stopped == 1 and notifications() == 1)

driver = setup().setup({})
callbacks.on_exit()
assert(stopped == 0 and notifications() == 1)

local module = setup()
spawn_result = 0
driver = module.setup({})
driver.temp_ascii()
assert(stopped == 0 and #sent == 0 and notifications() == 1)
print("wsl: OK")
