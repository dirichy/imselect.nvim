---The default strategy, will disable im in normal mode
---@type Imselect.Strategy
local M = { priority = 0 }
local default_opts = {
	inspecter = function()
		return (vim.api.nvim_get_mode().mode == "i" or vim.fn.getcmdtype() == "/" or vim.fn.getcmdtype() == "?")
	end,
}
function M.setup(opts)
	default_opts = vim.tbl_deep_extend("force", default_opts, opts)
	return M
end
M.inspecter = default_opts.inspecter
function M.condition(buffer)
	return true
end
return M
