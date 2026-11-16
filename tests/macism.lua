vim.opt.rtp:prepend(vim.fn.getcwd())

local function find_executable()
	return "macism"
end
require("imselect.util").find_executable = find_executable
local commands = {}
local source = "user.custom.input"
local fail = false
local function system(cmd, _, callback)
	commands[#commands + 1] = cmd
	local result = { code = fail and 1 or 0, stdout = "" }
	if not fail then
		if cmd[2] then
			source = cmd[2]
		else
			result.stdout = source .. "\n"
		end
	end
	if callback then
		callback(result)
	end
	return {
		wait = function()
			return result
		end,
	}
end
vim.system = system

local driver = require("imselect.util").with_restore(require("imselect.driver.macism").setup({}))
driver.temp_ascii()
assert(source == "com.apple.keylayout.ABC")
driver.restore()
assert(source == "user.custom.input", "restore the exact input source, not a fixed Chinese source")
assert(
	vim.deep_equal(commands, {
		{ "macism" },
		{ "macism", "com.apple.keylayout.ABC" },
		{ "macism", "user.custom.input" },
	}),
	vim.inspect(commands)
)
local before = #commands
driver.get_state(function(state)
	assert(state == source)
end)
assert(#commands == before + 1, "async queries must use their callback result without starting another process")
fail = true
assert(not pcall(driver.get_state))
driver.get_state(function(state)
	assert(state == nil)
end)
fail = false
driver.temp_ascii()
fail = true
assert(not pcall(driver.restore))
fail = false
driver.restore()
assert(source == "user.custom.input", "failed restoration must retain the original source for retry")
print("macism: OK")
