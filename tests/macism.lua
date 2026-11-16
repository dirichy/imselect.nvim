vim.opt.rtp:prepend(vim.fn.getcwd())

local function find_executable()
	return "macism"
end
require("imselect.util").find_executable = find_executable
local commands = {}
local function system(cmd)
	commands[#commands + 1] = cmd
	return {
		wait = function()
			return { stdout = "" }
		end,
	}
end
vim.system = system

local driver = require("imselect.driver.macism").setup({})
driver.active()
driver.disable()
assert(
	vim.deep_equal(commands, {
		{ "macism", "org.fcitx.inputmethod.Fcitx5.zhHans" },
		{ "macism", "com.apple.keylayout.ABC" },
	}),
	vim.inspect(commands)
)
print("macism: OK")
