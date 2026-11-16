vim.opt.rtp:prepend(vim.fn.getcwd())
vim.env.SSH_TTY = nil
vim.env.SSH_CONNECTION = nil
vim.env.SSH_CLIENT = nil

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
local applications = 0
local strategy = {
	name = "test",
	priority = 0,
	condition = function()
		applications = applications + 1
		return true
	end,
	inspecter = function(buf)
		return buf == first
	end,
}
require("imselect").setup({
	driver = "test",
	strategy = { strategy = { strategy } },
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
	"returning to a cached buffer must update the driver"
)
assert(events[3] == "restore" and applications == 2)

vim.api.nvim_set_current_buf(second)
vim.api.nvim_set_current_buf(first)
vim.wait(20)
assert(#events == 3, "queued updates must inspect the current buffer and avoid redundant driver calls")
print("buffer switch: OK")
