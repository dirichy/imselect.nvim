vim.opt.rtp:prepend(vim.fn.getcwd())
local ffi = require("ffi")
if ffi.os ~= "Windows" then
	local ok, err = pcall(require("imselect.driver.winime").setup)
	assert(not ok and tostring(err):find("native Windows", 1, true))
	package.loaded["imselect.driver.winime"] = nil
end

local focus = ffi.cast("void *", 0x11)
local active = ffi.cast("void *", 0x12)
local ime = ffi.cast("void *", 0x13)
local enabled = true
local no_focus, no_window, no_ime, no_thread, timeout = false, false, false, false, false
local queries, writes = 0, 0
local user32 = {
	GetGUIThreadInfo = function(thread, info)
		assert(thread == 0 and info.cbSize == ffi.sizeof(info))
		assert(ffi.sizeof(info) == (ffi.abi("64bit") and 72 or 48))
		if no_thread then
			return 0
		end
		info.hwndFocus = focus
		if no_focus or no_window then
			info.hwndFocus = nil
		end
		info.hwndActive = active
		if no_window then
			info.hwndActive = nil
		end
		return 1
	end,
	SendMessageTimeoutW = function(window, message, command, value, flags, ms, result)
		assert(window == ime and message == 0x0283 and flags == 0x0022 and ms == 100)
		if timeout then
			return 0
		end
		if command == 5 then
			queries = queries + 1
			result[0] = enabled and 1 or 0
		elseif command == 6 then
			writes = writes + 1
			enabled = value == 1
			result[0] = 0 -- The message result is distinct from successful delivery.
		else
			error("unexpected IME command")
		end
		return 1
	end,
}
local imm32 = {
	ImmGetDefaultIMEWnd = function(window)
		assert(window == (no_focus and active or focus))
		if no_ime then
			return ffi.cast("void *", 0)
		end
		return ime
	end,
}
package.loaded.ffi = setmetatable({
	os = "Windows",
	load = function(name)
		if name == "user32" then
			return user32
		end
		assert(name == "imm32")
		return imm32
	end,
}, { __index = ffi })
local driver = require("imselect.util").with_restore(require("imselect.driver.winime").setup({}))
driver.temp_ascii()
assert(enabled == false and queries == 1 and writes == 1)
driver.temp_ascii()
assert(queries == 1 and writes == 1)
timeout = true
assert(not pcall(driver.restore))
timeout = false
driver.restore()
assert(enabled == true and writes == 2)

enabled = false
driver.temp_ascii()
assert(writes == 2, "do not close an already closed IME")
driver.restore()
assert(enabled == false)
no_focus = true
assert(driver.get_state() == false, "fall back to the foreground active window when no child has focus")
no_focus = false
no_window = true
assert(not pcall(driver.get_state))
no_window = false
no_ime = true
assert(not pcall(driver.get_state))
no_ime = false
no_thread = true
assert(not pcall(driver.get_state))
print("winime: OK")
