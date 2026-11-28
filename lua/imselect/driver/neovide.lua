local util = require("imselect.util")
local M = {}
M.temp_ascii = function()
	vim.g.neovide_input_ime = false
end
M.restore = function()
	vim.g.neovide_input_ime = true
end
M.setup = util.once(function(opts)
	return M
end)
return M
