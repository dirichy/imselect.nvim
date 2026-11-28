local root = assert(vim.env.IMSELECT_DEMO_ROOT)
local scene = assert(vim.env.IMSELECT_DEMO_SCENE)
local chinese = vim.env.IMSELECT_DEMO_LANG == "zh"
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
vim.opt.statusline = " imselect.nvim | "
	.. (chinese and "手动切换输入法 0 次" or "0 manual input method switches")
	.. " %=%{mode() == 'i' ? 'INSERT' : mode() == 'c' ? 'COMMAND' : 'NORMAL'} "
-- Captions describe observed phases; they never alter input or editor contents.
local captions = {
	["initial normal"] = { "Normal mode: English input", "普通模式：自动使用英文" },
	["insert restores IME"] = { "Start writing in Chinese", "开始输入中文" },
	["uncommitted pinyin"] = { "Type Chinese", "输入中文" },
	["Chinese committed"] = {
		"Keep typing Chinese",
		"继续输入中文",
	},
	["snippet enters math"] = {
		"Jump into a formula: English input",
		"跳入公式：自动切换英文",
	},
	["math typed in ASCII"] = { "Write the formula", "用英文输入公式" },
	["prose restores IME in Insert"] = { "Jump back to prose: Chinese returns", "跳回正文：自动恢复中文" },
	["second formula"] = { "Next formula: English input", "进入下一段公式：再次自动英文" },
	["text inside math restores IME"] = {
		"Write Chinese text inside the formula",
		"公式里的文字，自动使用中文",
	},
	["nested Chinese"] = {
		"Keep writing Chinese inside the formula",
		"继续输入公式里的中文",
	},
	["Chinese committed again"] = { "Back to prose; keep writing", "回到正文，继续写作" },
	["third formula"] = { "A longer formula: keep typing", "再写一段更长的公式" },
	["long formula typed"] = { "Write a sum and a fraction", "求和与分式，全程使用英文输入" },
	["prose after long formula"] = {
		"Formula done: Chinese returns automatically",
		"公式完成：自动恢复中文",
	},
	["string restores IME"] = { "Move into a string: restore Chinese", "移入字符串：恢复中文输入" },
	["Chinese string"] = { "Write a Chinese message", "输入中文消息" },
	["Chinese comment"] = { "Comments use Chinese too", "注释同样自动使用中文" },
	["code selects ASCII"] = { "Back to code: English input", "修改代码行：自动使用英文" },
	["code typed in ASCII"] = {
		"Write the calculation",
		"代码使用英文，注释可以使用中文",
	},
	["comment restores IME"] = { "Move back to a comment: Chinese returns", "回到注释：自动恢复中文" },
	["new comment restores IME"] = {
		"Type -- after code: Chinese returns immediately",
		"在代码后输入 --：自动恢复中文",
	},
	["normal selects ASCII"] = {
		"Escape: back to commands",
		"按 Escape：回到普通模式，自动英文",
	},
	["forward Chinese search"] = {
		"/search: compose Chinese in the search prompt",
		"正向搜索：直接在搜索栏输入中文",
	},
	["search landed"] = { "Enter: jump to the match", "按回车：跳到匹配位置，恢复英文" },
	["backward Chinese search"] = {
		"?search: Chinese works in reverse search too",
		"反向搜索：同样自动恢复中文",
	},
	["backward search landed"] = { "Jump to the previous Chinese match", "跳到上一个中文匹配位置" },
	["editing restores IME again"] = { "Resume editing: Chinese returns", "继续编辑：自动恢复中文" },
	["Ex command stays ASCII"] = {
		":commands use English input",
		"命令使用英文，搜索恢复中文",
	},
	["final normal"] = {
		"All done. 0 manual input method switches.",
		"以上全部操作，手动切换输入法 0 次。",
	},
}
function _G.imselect_demo_caption(phase)
	local caption = assert(captions[phase], "missing demo caption: " .. phase)
	vim.opt.winbar = " " .. caption[chinese and 2 or 1]
	vim.cmd.redraw()
	return true
end
imselect_demo_caption("initial normal")
vim.opt.showmode = false
vim.opt.guicursor = ""
vim.opt.cursorline = true
vim.opt.fillchars = { eob = " " }
vim.cmd("syntax enable")
vim.bo.filetype = scene == "code" and "lua" or "tex"
vim.api.nvim_buf_set_name(0, session .. (scene == "code" and "/demo.lua" or "/demo.tex"))
local lines = scene == "code"
		and {
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			'local message = ""',
			"-- ",
			"local total = 0",
			"-- ",
			"print(message, total)",
		}
	or {
		"",
		"",
		"",
		"",
		"\\documentclass{article}",
		"\\begin{document}",
		"",
		"",
		scene == "modes" and "你好" or "",
		scene == "modes" and "世界" or "",
		"",
		"\\end{document}",
	}
local headings = {
	demo = {
		{ "Write Chinese prose and equations in one flow.", "连贯输入中文正文和公式。" },
		{
			"Ctrl-J: formula / next field; Ctrl-K: formula with text.",
			"Ctrl-J：展开公式或跳到下一处；Ctrl-K：带文字的公式。",
		},
	},
	code = {
		{ "Write Chinese messages and comments alongside code.", "写中文消息和注释，继续写代码。" },
	},
	modes = {
		{ "Write Chinese, search, and run commands.", "输入中文、搜索、执行命令。" },
	},
}
for row, heading in ipairs(headings[scene]) do
	lines[row] = (scene == "code" and "-- " or "% ") .. heading[chinese and 2 or 1]
end
vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
-- Demo-only snippet mappings; the plugin needs no snippet dependency.
if scene == "demo" then
	vim.keymap.set("i", "<C-j>", function()
		if vim.snippet.active({ direction = 1 }) then
			vim.snippet.jump(1)
		else
			vim.snippet.expand([[\$ ${1} \$$0]])
		end
	end)
	vim.keymap.set("i", "<C-k>", function()
		vim.snippet.expand([[\$ ${1} \\quad \\text{ ${2}} \$$0]])
	end)
end
vim.cmd("silent write")
local parser = assert(vim.treesitter.get_parser(0, scene == "code" and "lua" or "latex"))
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
		command = vim.fn.getcmdline(),
		number = vim.wo.number,
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
require("imselect").setup({
	driver = "fcitx",
})
vim.fn.writefile({ "ready" }, session .. "/ready")
