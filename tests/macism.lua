vim.opt.rtp:prepend(vim.fn.getcwd())

require("imselect.util").find_executable = function()
	return "macism"
end
local commands = {}
vim.system = function(cmd)
	commands[#commands + 1] = cmd
	return {
		wait = function()
			return { stdout = "" }
		end,
	}
end

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
