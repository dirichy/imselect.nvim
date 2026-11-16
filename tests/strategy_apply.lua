vim.opt.rtp:prepend(vim.fn.getcwd())

local imselect = require("imselect")
local manager = require("imselect.strategy.init")
local buffer = vim.api.nvim_get_current_buf()
local custom_enabled = true
local fallback_enabled = true
local fallback = function()
	return false
end
manager.setup({
	strategy_provider = {},
	strategy = {
		{
			name = "skipped",
			priority = 4,
			condition = function()
				return false
			end,
			apply = function()
				error("a nonmatching strategy must not run")
			end,
		},
		{
			name = "declining",
			priority = 3,
			condition = function()
				return true
			end,
			apply = function()
				return false
			end,
		},
		{
			name = "declining_with_inspecter",
			priority = 2,
			condition = function()
				return true
			end,
			apply = function()
				return false
			end,
			inspecter = function()
				error("a declining strategy must not install its inspector")
			end,
		},
		{
			name = "custom",
			priority = 1,
			condition = function()
				return custom_enabled
			end,
			apply = function(buf)
				return imselect.set_inspecter(buf, function()
					return true
				end)
			end,
		},
		{
			name = "fallback",
			priority = 0,
			condition = function()
				return fallback_enabled
			end,
			inspecter = fallback,
		},
	},
})

assert(manager.apply(buffer))
assert(imselect.inspect() == true, "custom apply must install its inspector and stop selection")
custom_enabled = false
assert(manager.apply(buffer))
assert(imselect.inspect() == false, "failed strategies must allow the fallback inspector")
fallback_enabled = false
assert(manager.apply(buffer) == false, "all declining strategies must report failure")
print("strategy apply: OK")
