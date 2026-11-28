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
	.. (chinese and "手动切换输入法 0 次" or "0 manual IME switches")
	.. " %=%{mode() == 'i' ? 'INSERT' : mode() == 'c' ? 'COMMAND' : 'NORMAL'} "
-- Captions describe observed phases; they never alter input or editor contents.
local captions = {
	["initial normal"] = { "Normal mode: ASCII is ready", "普通模式：自动使用英文" },
	["insert restores IME"] = { "Enter Insert: restore Chinese input", "进入插入模式：恢复中文输入" },
	["uncommitted pinyin"] = { "Real pinyin composition and candidate popup", "真实拼音组词与候选框" },
	["Chinese committed"] = {
		"Keep typing Chinese; no IME shortcut needed",
		"继续输入中文，无需切换输入法",
	},
	["snippet enters math"] = {
		"Jump into a formula: ASCII, still in Insert",
		"跳入公式：自动英文，仍在插入模式",
	},
	["math typed in ASCII"] = { "Write the formula in ASCII", "用英文输入公式" },
	["prose restores IME in Insert"] = { "Jump back to prose: Chinese returns", "跳回正文：自动恢复中文" },
	["second formula"] = { "Another formula: ASCII again", "进入下一段公式：再次自动英文" },
	["text inside math restores IME"] = {
		"Inside math, a text field restores Chinese",
		"公式中的文本字段：恢复中文输入",
	},
	["nested Chinese"] = {
		"Chinese inside the formula, without leaving Insert",
		"在公式内部输入中文，全程保持插入模式",
	},
	["Chinese committed again"] = { "Back to prose; keep writing", "回到正文，继续写作" },
	["third formula"] = { "A longer formula: keep typing", "再写一段更长的公式" },
	["long formula typed"] = { "Summation and fractions, all in ASCII", "求和与分式，全程使用英文输入" },
	["prose after long formula"] = {
		"Formula done: Chinese returns automatically",
		"公式完成：自动恢复中文",
	},
	["string restores IME"] = { "Move into a string: restore Chinese", "移入字符串：恢复中文输入" },
	["Chinese string"] = { "Chinese string entered through the real IME", "通过真实输入法输入中文字符串" },
	["Chinese comment"] = { "Comments use Chinese too", "注释同样自动使用中文" },
	["code selects ASCII"] = { "Change a code line: ASCII is ready", "修改代码行：自动使用英文" },
	["code typed in ASCII"] = {
		"Code uses ASCII; comments can use Chinese",
		"代码使用英文，注释可以使用中文",
	},
	["comment restores IME"] = { "Move back to a comment: Chinese returns", "回到注释：自动恢复中文" },
	["new comment restores IME"] = {
		"Type -- after code: Chinese returns immediately",
		"在代码后输入 --：自动恢复中文",
	},
	["normal selects ASCII"] = {
		"Escape: back to Normal, back to ASCII",
		"按 Escape：回到普通模式，自动英文",
	},
	["forward Chinese search"] = {
		"/search: compose Chinese in the search prompt",
		"正向搜索：直接在搜索栏输入中文",
	},
	["search landed"] = { "Enter: find the match and return to ASCII", "按回车：跳到匹配位置，恢复英文" },
	["backward Chinese search"] = {
		"?search: Chinese works in reverse search too",
		"反向搜索：同样自动恢复中文",
	},
	["backward search landed"] = { "Jump to the previous Chinese match", "跳到上一个中文匹配位置" },
	["editing restores IME again"] = { "Resume editing: Chinese returns", "继续编辑：自动恢复中文" },
	["Ex command stays ASCII"] = {
		":commands use ASCII; searches restore Chinese",
		"命令使用英文，搜索恢复中文",
	},
	["final normal"] = { "All done. 0 manual IME switches.", "以上全部操作，手动切换输入法 0 次。" },
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
			"-- Code in ASCII. Strings and comments in Chinese.",
			"-- No input-method hotkeys throughout this recording.",
			"-- Native editing commands; real fcitx5-rime input.",
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
		"% Real Chinese input. No manual IME switches.",
		scene == "demo" and "% Ctrl-J: math snippet / next field; Ctrl-K: math + text"
			or "% Search restores Chinese; :commands stay in ASCII.",
		scene == "demo" and "% Neovim built-in snippets; stay in Insert throughout."
			or "% Esc returns to ASCII. Insert restores Chinese again.",
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
if chinese then
	local prefix = scene == "code" and "-- " or "% "
	lines[1] = prefix
		.. (
			scene == "code" and "代码使用英文，字符串和注释使用中文。"
			or "真实中文输入，全程无需手动切换输入法。"
		)
	lines[2] = prefix
		.. (
			scene == "demo" and "Ctrl-J：展开公式或跳字段；Ctrl-K：公式内文本。"
			or scene == "code" and "使用原生编辑命令，观察输入法自动切换。"
			or "正反向搜索恢复中文，冒号命令保持英文。"
		)
	lines[3] = prefix
		.. (
			scene == "demo" and "Neovim 原生 snippet，全程保持插入模式。"
			or scene == "code" and "真实 fcitx5-rime 组词，无输入法切换快捷键。"
			or "Escape 切回英文，再次插入恢复中文。"
		)
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
