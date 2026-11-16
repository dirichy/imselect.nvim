vim.opt.rtp:prepend(vim.fn.getcwd())
local syntax = require("imselect.syntax")
vim.opt.virtualedit = "onemore"

local function check(filetype, lines, row, col, expected, message)
	local buffer = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_set_current_buf(buffer)
	vim.bo[buffer].filetype = filetype
	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
	vim.api.nvim_win_set_cursor(0, { row, col })
	assert(syntax.in_text(buffer) == expected, message)
end

check("lua", { "local value = 1" }, 1, 6, false, "identifiers are code")
check("lua", { 'local value = "hello"' }, 1, 16, true, "string content is text")
check("lua", { 'local value = ""' }, 1, 15, true, "empty string insertion is text")
check("lua", { 'local value = "hello"' }, 1, 21, false, "after a closing quote is code")
check("lua", { 'local value = "hello' }, 1, 20, true, "unfinished strings remain text")
check("lua", { "-- hello" }, 1, 5, true, "comments are text")
check("lua", { "-- hello" }, 1, 8, true, "typing at a line comment's end extends text")
check("lua", { "--" }, 1, 2, true, "new line comments allow text immediately")
check("lua", { "--[[ hello ]]" }, 1, 13, false, "after a block comment is code")
check("lua", { 'local value = "中文"' }, 1, 18, true, "columns are UTF-8 byte offsets")
check("text", { "plain text" }, 1, 5, true, "without a parser preserve mode-only switching")
check("markdown", { "some prose" }, 1, 3, true, "Markdown prose is text")
check("markdown", { "hello `value` world" }, 1, 9, false, "Markdown inline code is code")
check("markdown", { "```lua", "local value = 1", "```" }, 2, 6, false, "injected Lua is code")
check("markdown", { "```lua", "-- hello", "```" }, 2, 4, true, "injected Lua comments are text")
check(
	"markdown",
	{ "```unknown_language", "some code", "```" },
	2,
	4,
	false,
	"fences are code without an injected parser"
)
check("lua", { 'vim.cmd("let value = 1")' }, 1, 16, false, "injected Vim code overrides the host string")
check("lua", { [[vim.cmd("let value = 'hello'")]] }, 1, 26, true, "injected strings restore text")

-- Reparse edits in place, rather than retaining a stale text classification.
local buffer = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "-- hello" })
vim.api.nvim_win_set_cursor(0, { 1, 5 })
assert(syntax.in_text(buffer))
vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "local value = 1" })
assert(not syntax.in_text(buffer))
print("syntax: OK")
