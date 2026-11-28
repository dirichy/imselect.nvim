local M = {}

---@alias Imselect.Inspector fun(buffer:integer):boolean
---@class Imselect.Scope
---@field buffer? boolean|integer True/0 selects the current buffer; mutually exclusive with filetype.
---@field filetype? string|string[] Exact filetypes; nil selects global scope.

---@type Imselect.Inspector?
local global
---@type table<string, Imselect.Inspector>
local filetypes = {}
---@type table<integer, Imselect.Inspector>
local buffers = {}

---Set an Insert-mode inspector; nil removes the override at the given scope.
---@param fn? Imselect.Inspector
---@param opts? Imselect.Scope
function M.set(fn, opts)
	assert(fn == nil or type(fn) == "function", "inspector must be a function or nil")
	assert(opts == nil or type(opts) == "table", "scope must be a table")
	local buffer, filetype = opts and opts.buffer, opts and opts.filetype
	assert(
		buffer == nil or type(buffer) == "boolean" or type(buffer) == "number" and buffer % 1 == 0,
		"buffer must be boolean or integer"
	)
	assert(not (buffer and filetype), "choose either buffer or filetype scope")
	if buffer then
		local bufnr = type(buffer) == "number" and buffer ~= 0 and buffer or vim.api.nvim_get_current_buf()
		assert(vim.api.nvim_buf_is_valid(bufnr), "invalid buffer: " .. tostring(bufnr))
		buffers[bufnr] = fn
	elseif filetype ~= nil then
		assert(
			type(filetype) == "string" or type(filetype) == "table" and vim.islist(filetype),
			"filetype must be a string or list"
		)
		---@type string[]
		local names
		if type(filetype) == "string" then
			names = { filetype }
		else
			names = filetype
		end
		assert(#names > 0, "filetype list must not be empty")
		for _, name in ipairs(names) do
			assert(type(name) == "string" and name ~= "", "filetype must be a nonempty string")
		end
		for _, name in ipairs(names) do
			filetypes[name] = fn
		end
	else
		global = fn
	end
end

---@param buffer integer
---@return boolean
function M.inspect(buffer)
	local fn = buffers[buffer] or filetypes[vim.bo[buffer].filetype] or global
	if fn then
		return fn(buffer)
	end
	return require("imselect.syntax").in_text(buffer)
end

vim.api.nvim_create_autocmd("BufWipeout", {
	group = vim.api.nvim_create_augroup("ImselectInspectors", { clear = true }),
	callback = function(event)
		buffers[event.buf] = nil
	end,
})

return M
