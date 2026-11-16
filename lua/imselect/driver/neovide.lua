local util = require("imselect.util")
local M = {}
M.ascii_state = false
M.set_state = function(state)
	vim.g.neovide_input_ime = state
end
M.get_state = function()
	return vim.g.neovide_input_ime
end
M.setup = util.once(function(opts)
	return M
end)
return M
