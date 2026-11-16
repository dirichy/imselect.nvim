vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.virtualedit = "onemore"
local syntax = require("imselect.syntax")

local function check(lines, row, needle, expected, message)
	local buffer = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_set_current_buf(buffer)
	vim.bo[buffer].filetype = "tex"
	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
	-- Require a real LaTeX parser so fallback-to-text cannot hide failures.
	assert(vim.treesitter.get_parser(buffer, "latex"))
	local col = needle == "" and #lines[row] or assert(lines[row]:find(needle, 1, true)) - 1
	vim.api.nvim_win_set_cursor(0, { row, col })
	assert(syntax.in_text(buffer) == expected, message)
end
check({ "Some prose" }, 1, "prose", true, "LaTeX prose is text")
check({ "% a comment" }, 1, "comment", true, "LaTeX comments are text")
check({ "% a comment" }, 1, "", true, "LaTeX line comments extend at EOL")
check({ [[Some $x + y$ prose]] }, 1, "x", false, "inline math selects ASCII")
check({ [[Some \(x + y\) prose]] }, 1, "x", false, "parenthesized math selects ASCII")
check({ [=[\[x + y\]]=] }, 1, "x", false, "display math selects ASCII")
check({ [[\begin{equation}]], "x + y", [[\end{equation}]] }, 2, "x", false, "math environments select ASCII")
check({ [[$x + \text{some prose}$]] }, 1, "prose", true, "text inside math restores input")
check({ [[\begin{verbatim}]], "some code", [[\end{verbatim}]] }, 2, "code", true, "verbatim follows its comment node")
check({ [[\begin{verbatim}]], "some code", [[\end{verbatim}]] }, 2, "", true, "verbatim remains text at EOL")
check({ [[\begin{comment}]], "some text", [[\end{comment}]] }, 2, "text", true, "comment environments are text")
check({ [[\begin{lstlisting}]], "some code", [[\end{lstlisting}]] }, 2, "code", false, "listings select ASCII")
print("LaTeX syntax: OK")
