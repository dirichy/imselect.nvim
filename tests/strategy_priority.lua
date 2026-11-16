vim.opt.rtp:prepend(vim.fn.getcwd())

local visited = {}
local selected
local function strategy(name, priority)
	return {
		name = name,
		priority = priority,
		condition = function()
			visited[#visited + 1] = name
			return selected == name
		end,
		inspecter = function()
			return true
		end,
	}
end

local manager = require("imselect.strategy.init")
manager.setup({
	strategy = { strategy("high", 10), strategy("default", 0) },
	strategy_provider = { low = { enabled = true } },
})
local low = strategy("low", -1)
local setups = 0
low.setup = function(opts)
	assert(opts.enabled == true)
	setups = setups + 1
end
manager.add_strategy(low)
manager.add_strategy(strategy("equal_low", -1))
manager.add_strategy(strategy("middle", 5))
manager.add_strategy(strategy("equal_high", 10))

local buffer = vim.api.nvim_get_current_buf()
assert(manager.apply(buffer) == false)
assert(vim.deep_equal(visited, { "high", "equal_high", "middle", "default", "low", "equal_low" }), vim.inspect(visited))
assert(setups == 1)
selected = "low"
assert(manager.apply(buffer))
assert(require("imselect").inspect() == true)
print("strategy priority: OK")
