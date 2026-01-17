local M = {}
M.inspecters = { require("imselect.inspecter.nvimtex").setup(), require("imselect.inspecter.default").setup() }
function M.apply(buffer)
	for _, inspecter in ipairs(M.inspecters) do
		if inspecter.apply(buffer) then
			return true
		end
	end
end
--- add inspecter
---@param new_inspecter Imselect.Inspecter
function M.add_inspecter(new_inspecter)
	for index, inspecter in ipairs(M.inspecters) do
		if inspecter.priority < new_inspecter.priority then
			table.insert(M.inspecters, index, new_inspecter)
			return
		end
	end
end

return M
