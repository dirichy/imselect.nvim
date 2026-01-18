local M = {}
local default_opts = { strategy = { require("imselect.strategy.nvimtex"), require("imselect.strategy.default") } }
local util = require("imselect.util")
M.setup = util.once(function(opts)
	default_opts = vim.tbl_deep_extend("force", default_opts, opts)
	for _, strategy in ipairs(default_opts.strategy) do
		if strategy.setup then
			strategy.setup(default_opts.strategy_provider[strategy.name] or {})
		end
	end
	return M
end)
--- will apply all strategy from high priority to low priority on a buffer
---@param buffer number
---@return boolean
function M.apply(buffer)
	for _, strtgy in ipairs(default_opts.strategy) do
		if
			strtgy.condition(buffer)
			and (strtgy.apply and strtgy.apply(buffer) or require("imselect").set_inspecter(buffer, strtgy.inspecter))
		then
			return true
		end
	end
	return false
end
--- add strategy
---@param new_strategy Imselect.Strategy
function M.add_strategy(new_strategy)
	if new_strategy.setup then
		new_strategy.setup(default_opts.strategy_provider[new_strategy.name] or {})
	end
	for index, strtgy in ipairs(default_opts.strategy) do
		if strtgy.priority < new_strategy.priority then
			table.insert(default_opts.strategy, index, new_strategy)
			return
		end
	end
end

return M
