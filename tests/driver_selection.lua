vim.opt.rtp:prepend(vim.fn.getcwd())
local names = { "fcitx", "macism", "im_select", "winime", "wsl", "kitty", "neovide" }
local finders = {}
for _, name in ipairs({ "fcitx", "macism", "im_select", "wsl" }) do
	finders[name] = require("imselect.driver." .. name).find_command
end
local available, selected, setups
rawset(vim.fn, "executable", function(command)
	return available[command] and 1 or 0
end)
for _, name in ipairs(names) do
	package.preload["imselect.driver." .. name] = function()
		return {
			find_command = finders[name],
			setup = function()
				selected, setups = name, setups + 1
				return { temp_ascii = function() end, restore = function() end }
			end,
		}
	end
end
local system, wsl
vim.uv.os_uname = function()
	return { sysname = system }
end
local has = vim.fn.has
rawset(vim.fn, "has", function(feature)
	if feature == "wsl" then
		return wsl and 1 or 0
	end
	return has(feature)
end)
-- Distinct user environments, not every possible permutation of detector internals.
for _, case in ipairs({
	{ name = "Linux fcitx", commands = { "fcitx5-remote" }, expected = "fcitx" },
	{ name = "macOS macism", system = "Darwin", commands = { "macism" }, expected = "macism" },
	{ name = "macOS fcitx preferred", system = "Darwin", commands = { "fcitx5-remote", "macism" }, expected = "fcitx" },
	{ name = "Windows executable", system = "Windows_NT", commands = { "im-select.exe" }, expected = "im_select" },
	{ name = "Windows native fallback", system = "Windows_NT", expected = "winime" },
	{
		name = "WSL controls Windows even with Linux fcitx installed",
		wsl = true,
		commands = { "powershell.exe", "fcitx5-remote" },
		expected = "wsl",
	},
	{
		name = "WSL prefers an installed im-select",
		wsl = true,
		commands = { "im-select.exe", "powershell.exe" },
		expected = "im_select",
	},
	{
		name = "WSL without Windows PATH",
		wsl = true,
		commands = { "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe" },
		expected = "wsl",
	},
	{
		name = "custom executable path with spaces",
		wsl = true,
		commands = { "/mnt/c/My Tools/im-select.exe" },
		opts = { im_select = { command = "/mnt/c/My Tools/im-select.exe" } },
		expected = "im_select",
	},
	{ name = "no tool available" },
	{ name = "WSL without interop tools does not use Linux fcitx", wsl = true, commands = { "fcitx5-remote" } },
	{ name = "Neovide before SSH", neovide = true, ssh = true, expected = "neovide" },
	{ name = "SSH uses the local watcher", wsl = true, ssh = true, expected = "kitty" },
	{ name = "explicit driver overrides detection", ssh = true, opts = { driver = "fcitx" }, expected = "fcitx" },
	{ name = "disabled in supported environment", neovide = true, opts = { driver = false } },
	{ name = "custom selector", opts = {
		driver = function()
			return "fcitx"
		end,
	}, expected = "fcitx" },
	{ name = "custom selector opts out", opts = {
		driver = function()
			return nil
		end,
	} },
}) do
	vim.api.nvim_clear_autocmds({})
	for name in pairs(package.loaded) do
		if name == "imselect" or name:match("^imselect%.") then
			package.loaded[name] = nil
		end
	end
	available, selected, setups = {}, nil, 0
	for _, command in ipairs(case.commands or {}) do
		available[command] = true
	end
	system, wsl = case.system or "Linux", case.wsl or false
	vim.g.neovide = case.neovide or false
	vim.env.SSH_TTY, vim.env.SSH_CLIENT = nil, nil
	vim.env.SSH_CONNECTION = case.ssh and "test connection" or nil
	local imselect = require("imselect")
	imselect.setup(case.opts)
	imselect.setup(case.opts)
	assert(selected == case.expected, case.name .. ": selected " .. tostring(selected))
	assert(setups == (case.expected and 1 or 0), case.name .. ": repeated setup must not recreate the driver")
	if not case.expected then
		assert(#vim.api.nvim_get_autocmds({ event = "ModeChanged" }) == 0, case.name)
	end
end
print("driver selection: OK")
