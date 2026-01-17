local util = require("imselect.util")
local M = {}
M.active = function()
	vim.g.neovide_input_ime = true
end
M.disable = function()
	vim.g.neovide_input_ime = false
end
M.is_active = function()
	return vim.g.neovide_input_ime
end
M.setup = util.once(function(opts)
	return M
end)
return M
