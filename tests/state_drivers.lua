vim.opt.rtp:prepend(vim.fn.getcwd())
local util = require("imselect.util")
local function find_executable()
	return "fcitx5-remote"
end
util.find_executable = find_executable
local enabled = true
local fail = false
local commands = {}
local function system(args, opts, callback)
	assert(opts.timeout == 1000)
	commands[#commands + 1] = args
	if args[2] and not fail then
		enabled = args[2] == "-o"
	end
	local result = { code = fail and 1 or 0, stdout = enabled and "2\n" or "1\n", stderr = "unavailable" }
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
enabled = false
fcitx.get_state(function(state)
	assert(state == false)
end)
fail = true
assert(not pcall(fcitx.get_state), "failed queries must not be treated as inactive IMEs")
fcitx.get_state(function(state, err)
	assert(state == nil and err:find("unavailable", 1, true))
end)
fail = false
enabled = true
fcitx.temp_ascii()
fail = true
assert(not pcall(fcitx.restore))
fail = false
fcitx.restore()
assert(enabled == true, "failed commands must retain the original state for restoration")

local neovide = util.with_restore(require("imselect.driver.neovide").setup({}))
for _, state in ipairs({ true, false }) do
	vim.g.neovide_input_ime = state
	neovide.temp_ascii()
	assert(vim.g.neovide_input_ime == false)
	neovide.restore()
	assert(vim.g.neovide_input_ime == state)
end
print("state drivers: OK")
