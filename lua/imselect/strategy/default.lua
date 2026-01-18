---The default strategy, will disable im in normal mode
---@type Imselect.Strategy
local M = { priority = 0, name = "default" }
local default_opts = {
	inspecter = function()
		return (vim.api.nvim_get_mode().mode == "i" or vim.fn.getcmdtype() == "/" or vim.fn.getcmdtype() == "?")
	end,
}
local util = require("imselect.util")
M.setup = util.once(function(opts)
	default_opts = vim.tbl_deep_extend("force", default_opts, opts)
	return M
end)
M.inspecter = default_opts.inspecter
function M.condition(buffer)
	return true
end
return M
