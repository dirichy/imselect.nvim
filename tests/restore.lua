vim.opt.rtp:prepend(vim.fn.getcwd())
local state, failed = "user-input", false
local driver = require("imselect.util").with_restore({
	ascii_state = "ascii",
	get_state = function()
		return state
	end,
	set_state = function(value)
		if failed then
			error("input method unavailable")
		end
		state = value
	end,
})
-- Leaving text twice must still restore the original choice.
driver.restore()
assert(state == "user-input")
driver.temp_ascii()
driver.temp_ascii()
assert(state == "ascii")
driver.restore()
assert(state == "user-input")
-- A manual choice becomes the next restore target; a transient failure must not lose it.
driver.temp_ascii()
state = "manual-input"
driver.temp_ascii()
assert(state == "ascii")
failed = true
assert(not pcall(driver.restore))
failed = false
driver.restore()
assert(state == "manual-input")
print("restore: OK")
