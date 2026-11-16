---Restore text input in Insert/search; use ASCII in code and other modes.
---@type Imselect.Strategy
local M = { priority = 0, name = "default" }
local default_opts = {
	inspecter = function(buffer)
		if vim.fn.getcmdtype() == "/" or vim.fn.getcmdtype() == "?" then
			return true
		end
		return vim.api.nvim_get_mode().mode == "i" and require("imselect.syntax").in_text(buffer)
	end,
}
local util = require("imselect.util")
M.setup = util.once(function(opts)
	default_opts = vim.tbl_deep_extend("force", default_opts, opts)
	M.inspecter = default_opts.inspecter
	return M
end)
M.inspecter = default_opts.inspecter
function M.condition(buffer)
	return true
end
return M
