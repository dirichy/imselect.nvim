local M = { priority = 100 }
local default_opts = { filetype = { "tex", "latex" } }
function M.setup(opts)
	default_opts = vim.tbl_deep_extend("force", default_opts, opts)
	return M
end
function M.apply(buffer)
	local filetype = vim.bo[buffer].filetype
	if vim.tbl_contains(default_opts.filetype, filetype) then
		local ok, tex = pcall(require, "nvimtex.conditions.luasnip")
		if not ok then
			return false
		end
		require("imselect").set_inspecter(buffer, function()
			return tex.im_enable()
				and (vim.api.nvim_get_mode().mode == "i" or vim.fn.getcmdtype() == "/" or vim.fn.getcmdtype() == "?")
		end)
		return true
	end
end
return M
