-- An embedded Neovim processes real Insert-mode input without consuming this script's stdin.
local child = vim.fn.jobstart(
	{ vim.v.progpath, "--embed", "--headless", "-n", "-u", "NONE", "-i", "NONE" },
	{ rpc = true }
)
assert(child > 0)
---@return any RPC results depend on the requested Neovim method.
local function request(method, ...)
	return vim.rpcrequest(child, method, ...)
end
local function wait_state(mode, enabled, message)
	assert(
		vim.wait(1000, function()
			return request("nvim_get_mode").mode == mode and request("nvim_get_var", "neovide_input_ime") == enabled
		end),
		message
	)
end
local ok, err = pcall(function()
	request(
		"nvim_exec_lua",
		[[
		vim.opt.rtp:prepend(vim.fn.getcwd())
		vim.env.SSH_TTY = nil
		vim.env.SSH_CONNECTION = nil
		vim.env.SSH_CLIENT = nil
		vim.g.neovide = true
		vim.g.neovide_input_ime = true
		vim.bo.filetype = "lua"
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local value = 1", "-- hello", 'local text = "hello"' })
		require("imselect").setup()
	]],
		{}
	)
	wait_state("n", false, "Normal mode selects ASCII")
	request("nvim_input", "i")
	wait_state("i", false, "Insert in code stays ASCII")
	request("nvim_set_var", "neovide_input_ime", true)
	request("nvim_input", "x")
	assert(vim.wait(1000, function()
		return request("nvim_get_current_line"):sub(1, 1) == "x"
	end))
	assert(request("nvim_get_var", "neovide_input_ime") == true, "typing in code preserves a manual IME choice")
	request(
		"nvim_exec_lua",
		[[
		vim.opt.completeopt = { "menuone", "noselect" }
		vim.schedule(function()
			vim.fn.complete(1, { "xlocal_one", "xlocal_two" })
		end)
	]],
		{}
	)
	wait_state("ic", true, "Insert completion must preserve a manual IME choice in code")
	request("nvim_input", "<C-e>")
	wait_state("i", true, "closing completion stays in Insert without reapplying ASCII")
	request("nvim_input", "<C-x>")
	wait_state("ix", true, "CTRL-X completion is also an Insert submode")
	request("nvim_input", "<C-e>")
	wait_state("i", true, "leaving CTRL-X completion preserves the manual choice")
	request("nvim_input", "<Esc>")
	wait_state("n", false, "leaving code must reconcile a manual IME change even when both policies select ASCII")
	request("nvim_input", "i")
	wait_state("i", false, "reentering code stays ASCII")
	request("nvim_win_set_cursor", 0, { 2, 5 })
	wait_state("i", true, "moving into a comment restores the input method")
	request("nvim_win_set_cursor", 0, { 1, 6 })
	wait_state("i", false, "moving back into code selects ASCII")
	request("nvim_win_set_cursor", 0, { 3, 15 })
	wait_state("i", true, "moving into a string restores the input method")
	request("nvim_input", "<Esc>")
	wait_state("n", false, "leaving Insert selects ASCII in text too")
	request("nvim_input", "i")
	wait_state("i", true, "reentering text restores the original input method")
	request("nvim_input", "<Esc>")
	wait_state("n", false, "Normal mode selects ASCII again")
	request("nvim_win_set_cursor", 0, { 2, 5 })
	request("nvim_input", "i")
	wait_state("i", true, "comments restore text input")
	-- The replacement changes syntax without moving the insertion point.
	request("nvim_buf_set_lines", 0, 1, 2, false, { "local value = 1" })
	wait_state("i", false, "TextChangedI reparses syntax without a cursor move")
	request("nvim_input", "<Esc>")
	wait_state("n", false, "final Normal mode")
end)
vim.fn.jobstop(child)
assert(ok, err)
print("syntax switching: OK")
