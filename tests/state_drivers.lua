vim.opt.rtp:prepend(vim.fn.getcwd())
local util = require("imselect.util")
local function find_executable()
	return "fcitx5-remote"
end
util.find_executable = find_executable
local enabled = true
local commands = {}
local function system(args, _, callback)
	commands[#commands + 1] = args
	if args[2] then
		enabled = args[2] == "-o"
	end
	local result = { code = 0, stdout = enabled and "2\n" or "1\n" }
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
local fcitx = util.with_restore(require("imselect.driver.fcitx").setup({}))
fcitx.temp_ascii()
assert(enabled == false)
fcitx.restore()
assert(enabled == true)
assert(vim.deep_equal(commands, { { "fcitx5-remote" }, { "fcitx5-remote", "-c" }, { "fcitx5-remote", "-o" } }))
fcitx.get_state(function(state)
	assert(state == true)
end)

local neovide = util.with_restore(require("imselect.driver.neovide").setup({}))
for _, state in ipairs({ true, false }) do
	vim.g.neovide_input_ime = state
	neovide.temp_ascii()
	assert(vim.g.neovide_input_ime == false)
	neovide.restore()
	assert(vim.g.neovide_input_ime == state)
end
print("state drivers: OK")
