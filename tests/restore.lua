vim.opt.rtp:prepend(vim.fn.getcwd())
local util = require("imselect.util")

for _, case in ipairs({
	{ state = true, ascii = false },
	{ state = false, ascii = false },
	{ state = "custom-input", ascii = "ascii-input" },
	{ state = "ascii-input", ascii = "ascii-input" },
}) do
	local state = case.state
	local queries, writes = 0, 0
	local driver = util.with_restore({
		ascii_state = case.ascii,
		get_state = function()
			queries = queries + 1
			return state
		end,
		set_state = function(value)
			writes = writes + 1
			state = value
		end,
	})
	driver.restore()
	assert(queries == 0 and writes == 0)
	driver.temp_ascii()
	assert(state == case.ascii)
	assert(writes == (case.state == case.ascii and 0 or 1))
	local before = writes
	driver.temp_ascii()
	assert(queries == 1 and writes == before, "repeated calls must preserve the original state")
	driver.restore()
	assert(state == case.state)
	driver.restore()
	assert(writes == before + 1)
end

local state = "original"
local fail = false
local driver = util.with_restore({
	ascii_state = "ascii",
	get_state = function()
		return state
	end,
	set_state = function(value)
		if fail then
			error("write failed")
		end
		state = value
	end,
})
driver.temp_ascii()
fail = true
assert(not pcall(driver.restore))
fail = false
driver.restore()
assert(state == "original")

local direct = { temp_ascii = function() end, restore = function() end }
assert(util.with_restore(direct) == direct)
local unknown = util.with_restore({
	ascii_state = false,
	get_state = function()
		return nil
	end,
	set_state = function()
		error("must not write an unknown state")
	end,
})
assert(not pcall(unknown.temp_ascii))
unknown.restore()
print("restore: OK")
