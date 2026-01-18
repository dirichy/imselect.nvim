---This strategy is to select im in latex file, smartly disable im in math environment.
---@type Imselect.Strategy
local M = { priority = 100 }
local default_opts = { filetype = { "tex", "latex" } }
function M.setup(opts)
	default_opts = vim.tbl_deep_extend("force", default_opts, opts)
	return M
end
local tex
function M.condition(buffer)
	local filetype = vim.bo[buffer].filetype
	local flag = vim.tbl_contains(default_opts.filetype, filetype)
	if flag then
		local ok
		ok, tex = pcall(require, "nvimtex.conditions.luasnip")
		if not ok then
			return false
		end
		return true
	end
	return false
end

function M.inspecter(buffer)
	return tex.im_enable()
		and (vim.api.nvim_get_mode().mode == "i" or vim.fn.getcmdtype() == "/" or vim.fn.getcmdtype() == "?")
end
return M
