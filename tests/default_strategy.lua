local child = vim.fn.jobstart(
	{ vim.v.progpath, "--embed", "--headless", "-n", "-u", "NONE", "-i", "NONE" },
	{ rpc = true }
)
assert(child > 0)
local function request(method, ...)
	return vim.rpcrequest(child, method, ...)
end
local function wait_state(mode, enabled)
	assert(
		vim.wait(1000, function()
			return request("nvim_get_mode").mode == mode and request("nvim_get_var", "neovide_input_ime") == enabled
		end),
		"unexpected mode/input state: " .. mode .. "/" .. tostring(enabled)
	)
end
local ok, err = pcall(function()
	request(
		"nvim_exec_lua",
		[[
		vim.opt.rtp:prepend(vim.fn.getcwd())
		vim.g.neovide = true
		vim.g.neovide_input_ime = true
		vim.g.inspector_calls = 0
		vim.g.context_enabled = true
		local inspecter = function(buffer)
			assert(buffer == vim.api.nvim_get_current_buf())
			assert(vim.api.nvim_get_mode().mode:sub(1, 1) == "i", "custom inspectors only run in Insert")
			vim.g.inspector_calls = vim.g.inspector_calls + 1
			return vim.g.context_enabled
		end
		require("imselect").setup({
			strategy = { strategy_provider = { default = { inspecter = inspecter } } },
		})
		assert(require("imselect.strategy.default").inspecter == inspecter)
	]],
		{}
	)
	wait_state("n", false)
	assert(request("nvim_get_var", "inspector_calls") == 0)
	request("nvim_input", "i")
	wait_state("i", true)
	request(
		"nvim_exec_lua",
		[[
		vim.opt.completeopt = { "menuone", "noselect" }
		vim.schedule(function()
			vim.fn.complete(1, { "alpha", "beta" })
		end)
	]],
		{}
	)
	wait_state("ic", true)
	request(
		"nvim_exec_lua",
		[[
		vim.g.context_enabled = false
		require("imselect").update()
	]],
		{}
	)
	wait_state("ic", false)
	request("nvim_input", "<C-e>")
	wait_state("i", false)
	local calls = request("nvim_get_var", "inspector_calls")
	request("nvim_input", "<Esc>")
	wait_state("n", false)
	assert(request("nvim_get_var", "inspector_calls") == calls, "Normal bypasses the cursor inspector")
	request("nvim_input", "/")
	wait_state("c", true)
	assert(request("nvim_get_var", "inspector_calls") == calls, "search bypasses the cursor inspector")
	request("nvim_input", "<Esc>")
	wait_state("n", false)
	request("nvim_input", ":")
	wait_state("c", false)
	assert(request("nvim_get_var", "inspector_calls") == calls, "commands bypass the cursor inspector")
	request("nvim_input", "<Esc>")
	wait_state("n", false)
end)
vim.fn.jobstop(child)
assert(ok, err)
print("default strategy: OK")
