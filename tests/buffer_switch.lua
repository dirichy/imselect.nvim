vim.opt.rtp:prepend(vim.fn.getcwd())
vim.env.SSH_TTY = nil
vim.env.SSH_CONNECTION = nil
vim.env.SSH_CLIENT = nil
-- Isolate buffer selection from mode requirements; real key transitions are tested separately.
rawset(vim.api, "nvim_get_mode", function()
	return { mode = "i", blocking = false }
end)

local events = {}
package.preload["imselect.driver.test"] = function()
	return {
		setup = function()
			return {
				temp_ascii = function()
					events[#events + 1] = "temp_ascii"
				end,
				restore = function()
					events[#events + 1] = "restore"
				end,
			}
		end,
	}
end
local first = vim.api.nvim_get_current_buf()
local second = vim.api.nvim_create_buf(true, false)
local imselect = require("imselect")
imselect.set_inspector(function()
	return false
end, { buffer = second })
imselect.setup({
	driver = "test",
	inspector = function()
		return true
	end,
})
assert(vim.deep_equal(events, { "restore" }))

vim.api.nvim_set_current_buf(second)
assert(
	vim.wait(1000, function()
		return #events == 2
	end),
	"switching buffers must update the driver"
)
assert(events[2] == "temp_ascii")
vim.api.nvim_set_current_buf(first)
assert(
	vim.wait(1000, function()
		return #events == 3
	end),
	"returning to the first buffer must update the driver"
)
assert(events[3] == "restore")

vim.api.nvim_set_current_buf(second)
vim.api.nvim_set_current_buf(first)
vim.wait(20)
assert(#events == 3, "queued updates must inspect the current buffer and avoid redundant driver calls")

imselect.set_inspector(function()
	return false
end, { filetype = "text" })
vim.bo[first].filetype = "text"
assert(
	vim.wait(1000, function()
		return #events == 4
	end),
	"changing filetype must update the driver"
)
assert(events[4] == "temp_ascii")
imselect.set_inspector(nil, { filetype = "text" })
imselect.update()
assert(events[5] == "restore", "removing an override takes effect on the next update")

imselect.set_inspector(function()
	return false
end, { buffer = first })
vim.bo[first].filetype = "lua"
assert(vim.wait(1000, function()
	return #events == 6
end))
assert(events[6] == "temp_ascii", "FileType must preserve buffer overrides")
print("buffer switch: OK")
