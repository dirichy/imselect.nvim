local M = {}
M.strategy = { require("imselect.strategy.nvimtex").setup({}), require("imselect.strategy.default").setup({}) }
--- will apply all strategy from high priority to low priority on a buffer
---@param buffer number
---@return boolean
function M.apply(buffer)
	for _, strtgy in ipairs(M.strategy) do
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
	for index, strtgy in ipairs(M.strategy) do
		if strtgy.priority < new_strategy.priority then
			table.insert(M.strategy, index, new_strategy)
			return
		end
	end
end

return M
