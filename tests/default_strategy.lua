vim.opt.rtp:prepend(vim.fn.getcwd())
vim.env.SSH_TTY = nil
vim.env.SSH_CONNECTION = nil
vim.env.SSH_CLIENT = nil
vim.g.neovide = true
vim.g.neovide_input_ime = true

local buffer = vim.api.nvim_get_current_buf()
local enabled = false
local calls = 0
local inspecter = function(buf)
	assert(buf == buffer)
	calls = calls + 1
	return enabled
end
local imselect = require("imselect")
imselect.setup({
	strategy = { strategy_provider = { default = { inspecter = inspecter } } },
})
assert(require("imselect.strategy.default").inspecter == inspecter)
assert(calls == 1 and vim.g.neovide_input_ime == false)
enabled = true
imselect.update()
assert(calls == 2 and vim.g.neovide_input_ime == true)
print("default strategy: OK")
