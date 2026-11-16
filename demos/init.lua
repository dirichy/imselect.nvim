local root = assert(vim.env.IMSELECT_DEMO_ROOT)
local session = assert(vim.env.IMSELECT_DEMO_SESSION)
vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:prepend(root .. "/.dev/tokyonight.nvim")
vim.opt.termguicolors = true
require("tokyonight").setup({ style = "night" })
vim.cmd.colorscheme("tokyonight-night")
vim.opt.swapfile = false
vim.opt.laststatus = 2
vim.opt.statusline = " imselect.nvim %=%{mode() == 'i' ? 'INSERT' : 'NORMAL'} "
vim.opt.showmode = false
vim.opt.guicursor = ""
vim.opt.cursorline = true
vim.opt.fillchars = { eob = " " }
vim.cmd("syntax enable")
vim.bo.filetype = "markdown"
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
	"# imselect.nvim",
	"Insert: `i` → nihao + Space. `Esc` → ASCII navigation with 0l.",
	"Restore: `A` → shijie + Space. Your input method returns.",
	"",
})
vim.api.nvim_win_set_cursor(0, { 4, 0 })

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
