local M = {}

-- Nearest classified ancestor wins; interpolation can override a surrounding string.
local common = {
	string = true,
	string_content = true,
	string_literal = true,
	string_fragment = true,
	raw_string_literal = true,
	interpreted_string_literal = true,
	template_string = true,
	char_literal = true,
	character_literal = true,
	comment = true,
	line_comment = true,
	block_comment = true,
	multiline_comment = true,
	doc_comment = true,
	documentation_comment = true,
	interpolation = false,
	template_substitution = false,
	interpolated_expression = false,
	command_substitution = false,
}
local languages = {
	comment = { source = true },
	luadoc = { document = true },
	jsdoc = { document = true },
	markdown = { document = true, fenced_code_block = false, indented_code_block = false, code_fence_content = false },
	markdown_inline = { inline = true, code_span = false, latex_block = false },
	html = { text = true, quoted_attribute_value = true },
	vue = { text = true, quoted_attribute_value = true },
	latex = {
		source_file = true,
		inline_formula = false,
		displayed_equation = false,
		math_environment = false,
		text_mode = true,
		comment_environment = true,
		listing_environment = false,
		minted_environment = false,
		luacode_environment = false,
		pycode_environment = false,
		sageblock_environment = false,
		sagesilent_environment = false,
		asy_environment = false,
		asydef_environment = false,
		source_code = false,
	},
}

---@param node? TSNode
---@param language string
---@return boolean
local function in_text(node, language)
	local rules = languages[language] or {}
	while node do
		local kind = node:type()
		local text = rules[kind]
		if text == nil then
			text = common[kind]
		end
		if text ~= nil then
			return text
		end
		node = node:parent()
	end
	return false
end

--- Classify the insertion point; unavailable parsers preserve mode-only switching.
---@param buffer number
---@return boolean
function M.in_text(buffer)
	local filetype = vim.bo[buffer].filetype
	local language = (filetype == "tex" or filetype == "plaintex") and "latex" or nil
	local ok, parser = pcall(vim.treesitter.get_parser, buffer, language)
	if not ok or not parser then
		return true
	end
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]
	local parsed = pcall(parser.parse, parser, { row, row + 1 })
	if not parsed then
		return true
	end
	local range = { row, col, row, col }
	local language_tree = parser:language_for_range(range)
	local tree = language_tree:tree_for_range(range)
	if not tree then
		return true
	end
	local root = tree:root()
	local node = root:named_descendant_for_range(unpack(range))
	if in_text(node, language_tree:lang()) then
		return true
	end
	-- Line comments end before the insertion point at EOL, but typing extends them.
	local line = vim.api.nvim_buf_get_lines(buffer, row, row + 1, false)[1] or ""
	if col > 0 and col == #line then
		node = root:named_descendant_for_range(row, col - 1, row, col - 1)
		while node do
			local kind = node:type()
			if kind == "comment" or kind == "line_comment" then
				local last = node:child(node:child_count() - 1)
				-- An explicit closing delimiter ends a block comment.
				return not last or last:named()
			end
			if common[kind] ~= nil then
				break
			end
			node = node:parent()
		end
	end
	return false
end

return M
