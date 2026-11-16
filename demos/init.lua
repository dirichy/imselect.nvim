local root = assert(vim.env.IMSELECT_DEMO_ROOT)
local session = assert(vim.env.IMSELECT_DEMO_SESSION)
vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:prepend(root .. "/.dev/tokyonight.nvim")
vim.opt.runtimepath:prepend(root .. "/.dev/latex")
vim.opt.termguicolors = true
require("tokyonight").setup({ style = "night" })
vim.cmd.colorscheme("tokyonight-night")
vim.api.nvim_set_hl(0, "Comment", { fg = "#a9b1d6", italic = false })
vim.opt.swapfile = false
vim.opt.laststatus = 2
vim.opt.statusline = " imselect.nvim | demo.tex %=%{mode() == 'i' ? 'INSERT' : 'NORMAL'} "
vim.opt.showmode = false
vim.opt.guicursor = ""
vim.opt.cursorline = true
vim.opt.fillchars = { eob = " " }
vim.cmd("syntax enable")
vim.bo.filetype = "tex"
vim.api.nvim_buf_set_name(0, session .. "/demo.tex")
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
	"% imselect.nvim: mode switching + syntax awareness",
	"% MODE    i: restore IME | Esc: ASCII",
	"% SYNTAX  Chinese -> $ $ -> Left -> x + y -> Right -> Chinese",
	"",
	"\\documentclass{article}",
	"\\begin{document}",
	"",
	"",
	"",
	"\\end{document}",
})
vim.cmd("silent write")
local parser = assert(vim.treesitter.get_parser(0, "latex"))
assert(parser:parse())
vim.api.nvim_win_set_cursor(0, { 8, 0 })

local events = {}
vim.api.nvim_create_autocmd({ "ModeChanged", "TextChangedI", "TextChanged" }, {
	callback = function(event)
		events[#events + 1] = { event = event.event, mode = vim.api.nvim_get_mode().mode }
	end,
})
function _G.imselect_demo_snapshot()
	return {
		mode = vim.api.nvim_get_mode().mode,
		lines = vim.api.nvim_buf_get_lines(0, 0, -1, false),
		cursor = vim.api.nvim_win_get_cursor(0),
		in_text = require("imselect.syntax").in_text(vim.api.nvim_get_current_buf()),
		parser = parser:lang(),
		events = events,
		error = vim.v.errmsg,
	}
end

assert(
	vim.wait(15000, function()
		return vim.fn.filereadable(session .. "/start") == 1
	end),
	"timed out waiting for the XIM input context"
)
require("imselect").setup({ default_driver = { Linux = "fcitx" }, enable_in_ssh = false })
vim.fn.writefile({ "ready" }, session .. "/ready")
