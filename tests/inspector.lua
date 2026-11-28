vim.opt.rtp:prepend(vim.fn.getcwd())

local imselect = require("imselect")
local first = vim.api.nvim_get_current_buf()
local second = vim.api.nvim_create_buf(true, false)
vim.bo[first].filetype = "lua"
vim.bo[second].filetype = "lua"
local selected
local function inspector(scope, result)
	return function(buffer)
		assert(buffer == vim.api.nvim_get_current_buf())
		selected = scope
		return result
	end
end
local function expect(scope, result)
	assert(imselect.inspect() == result)
	assert(selected == scope, tostring(selected))
end

imselect.set_inspector(inspector("global", true))
expect("global", true)
imselect.set_inspector(inspector("filetype", false), { filetype = { "lua", "text" } })
expect("filetype", false)
imselect.set_inspector(inspector("buffer", true), { buffer = true })
expect("buffer", true)
vim.bo[first].filetype = "text"
expect("buffer", true)
vim.api.nvim_set_current_buf(second)
expect("filetype", false)
imselect.set_inspector(inspector("second", true), { buffer = 0 })
expect("second", true)
imselect.set_inspector(nil, { buffer = second })
expect("filetype", false)
vim.bo[second].filetype = "text"
expect("filetype", false)
vim.bo[second].filetype = "python"
expect("global", true)
imselect.set_inspector(inspector("replacement", false))
expect("replacement", false)
vim.api.nvim_set_current_buf(first)
expect("buffer", true)
imselect.set_inspector(nil, { buffer = first })
expect("filetype", false)
imselect.set_inspector(nil, { filetype = { "lua", "text" } })
expect("replacement", false)
imselect.set_inspector(nil)
assert(imselect.inspect() == require("imselect.syntax").in_text(first), "removing global restores syntax detection")

-- Reject an invalid scope without partially changing valid registrations.
imselect.set_inspector(inspector("filetype", false), { filetype = "text" })
local fn = inspector("invalid", true)
for _, scope in ipairs({
	{ buffer = true, filetype = "text" },
	{ buffer = -1 },
	{ buffer = 1.5 },
	{ buffer = "current" },
	{ filetype = {} },
	{ filetype = "" },
	{ filetype = false },
	{ filetype = { "text", false } },
}) do
	assert(not pcall(imselect.set_inspector, fn, scope), vim.inspect(scope))
end
expect("filetype", false)

-- An inspector closure must live as long as its buffer, including :bdelete,
-- and become collectible on :bwipeout, even before setup() is called.
local weak = setmetatable({}, { __mode = "v" })
do
	local captured = {}
	local retained = function()
		return captured ~= nil
	end
	weak[1] = retained
	imselect.set_inspector(retained, { buffer = second })
end
vim.api.nvim_set_current_buf(second)
vim.api.nvim_set_current_buf(first)
vim.cmd("bdelete " .. second)
collectgarbage("collect")
assert(weak[1], "bdelete preserves buffer-local registrations")
vim.api.nvim_set_current_buf(second)
assert(imselect.inspect() == true)
vim.api.nvim_set_current_buf(first)
vim.api.nvim_buf_delete(second, { force = true })
collectgarbage("collect")
collectgarbage("collect")
assert(weak[1] == nil, "wipeout releases the inspector and its captured state")
expect("filetype", false)
print("inspector: OK")
