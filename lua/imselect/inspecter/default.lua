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
function M.apply(buffer)
	require("imselect").set_inspecter(buffer, default_opts.inspecter)
	return true
end
return M
