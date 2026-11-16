vim.opt.rtp:prepend(vim.fn.getcwd())

local util = require("imselect.util")
for _, case in ipairs({ {}, { value = false }, { value = "result" }, { value = {} } }) do
	local calls = 0
	local once = util.once(function(arg)
		calls = calls + 1
		assert(arg == "first")
		return case.value
	end)
	assert(once("first") == case.value)
	assert(once("second") == case.value)
	assert(calls == 1)
end

local attempts = 0
local retry = util.once(function()
	attempts = attempts + 1
	if attempts == 1 then
		error("setup failed")
	end
	return true
end)
assert(not pcall(retry))
assert(retry() and retry() and attempts == 2)

vim.env.SSH_TTY = nil
vim.env.SSH_CONNECTION = nil
vim.env.SSH_CLIENT = nil
vim.g.neovide = true
vim.g.neovide_input_ime = true
local imselect = require("imselect")
imselect.setup()
local autocmds = vim.api.nvim_get_autocmds({ event = "ModeChanged" })
assert(#autocmds == 1)
imselect.setup()
assert(#vim.api.nvim_get_autocmds({ event = "ModeChanged" }) == #autocmds)
print("once: OK")
