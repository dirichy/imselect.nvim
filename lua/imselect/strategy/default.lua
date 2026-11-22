---Classify the Insert-mode cursor context; mode requirements belong to the caller.
---@type Imselect.Strategy
local M = { priority = 0, name = "default" }
local default_opts = {
	inspecter = function(buffer)
		return require("imselect.syntax").in_text(buffer)
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
