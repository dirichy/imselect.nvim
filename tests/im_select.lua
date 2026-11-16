vim.opt.rtp:prepend(vim.fn.getcwd())
local util = require("imselect.util")
local function executable(path)
	assert(path == "/test/im-select.exe")
	return 1
end
vim.fn.executable = executable
local layout = "2052"
local fail = false
local commands = {}
local function system(args, opts)
	assert(opts.timeout == 1000)
	commands[#commands + 1] = args
	return {
		wait = function()
			if fail then
				return { code = 1, stderr = "command failed" }
			end
			if args[2] then
				layout = args[2]
			end
			return { code = 0, stdout = args[2] and "" or layout .. "\r\n" }
		end,
	}
end
vim.system = system
local driver = util.with_restore(require("imselect.driver.im_select").setup({ command = "/test/im-select.exe" }))
driver.restore()
assert(#commands == 0)
driver.temp_ascii()
assert(layout == "1033")
assert(vim.deep_equal(commands, { { "/test/im-select.exe" }, { "/test/im-select.exe", "1033" } }))
driver.temp_ascii()
assert(#commands == 2)
fail = true
assert(not pcall(driver.restore))
fail = false
driver.restore()
assert(layout == "2052", "restore the original ID after a failed restoration")
driver.restore()
assert(#commands == 4)

layout = "1033"
local before = #commands
driver.temp_ascii()
assert(#commands == before + 1, "do not switch an already ASCII layout")
driver.restore()
layout = "invalid"
assert(not pcall(driver.temp_ascii))
layout = "2057"
fail = true
assert(not pcall(driver.temp_ascii))
fail = false
driver.temp_ascii()
driver.restore()
assert(layout == "2057")

package.loaded["imselect.driver.im_select"] = nil
driver =
	util.with_restore(require("imselect.driver.im_select").setup({ command = "/test/im-select.exe", ascii = "2057" }))
layout = "2052"
driver.temp_ascii()
assert(layout == "2057")
driver.restore()
assert(layout == "2052")
print("im-select: OK")
