vim.opt.rtp:prepend(vim.fn.getcwd())

local finders = {}
for _, name in ipairs({ "fcitx", "macism", "im_select", "wsl" }) do
	finders[name] = require("imselect.driver." .. name).find_command
end
local available = {}
vim.fn.executable = function(command)
	return available[command] and 1 or 0
end

local selected
---@type {marker?: boolean}?
local driver_opts
local updates = 0
for _, name in ipairs({ "neovide", "kitty", "fcitx", "macism", "test_ssh", "test_os", "im_select", "winime", "wsl" }) do
	package.preload["imselect.driver." .. name] = function()
		return {
			find_command = finders[name],
			setup = function(opts)
				assert(selected == nil, "only one driver should be initialized")
				selected = name
				driver_opts = opts
				return {
					temp_ascii = function()
						updates = updates + 1
					end,
					restore = function()
						updates = updates + 1
					end,
				}
			end,
		}
	end
end

local system
local wsl
local has = vim.fn.has
rawset(vim.fn, "has", function(feature)
	if feature == "wsl" then
		return wsl and 1 or 0
	end
	return has(feature)
end)
local function os_uname()
	return { sysname = system }
end
vim.uv.os_uname = os_uname
local cases = {
	{ name = "disabled driver", driver = false },
	{ name = "disabled driver in Neovide over SSH", neovide = true, ssh = true, driver = false },
	{ name = "selector returns false", custom = true, result = false },
	{ name = "fixed driver", driver = "test_os", expected = "test_os" },
	{
		name = "fixed driver overrides Neovide and SSH",
		neovide = true,
		ssh = true,
		driver = "fcitx",
		expected = "fcitx",
	},
	{ name = "fixed driver on unsupported OS", system = "unknown", driver = "test_os", expected = "test_os" },
	{ name = "Neovide over SSH", neovide = true, ssh = true, expected = "neovide" },
	{ name = "local Neovide", neovide = true, expected = "neovide" },
	{ name = "SSH defaults to Kitty", ssh = true, expected = "kitty" },
	{ name = "Linux driver", system = "Linux", commands = { "fcitx5-remote" }, expected = "fcitx" },
	{ name = "Linux legacy fcitx", commands = { "fcitx-remote" }, expected = "fcitx" },
	{ name = "Linux without drivers" },
	{ name = "WSL default driver", wsl = true, commands = { "im-select.exe" }, expected = "im_select" },
	{
		name = "WSL prefers Windows IME over Linux fcitx",
		wsl = true,
		commands = { "im-select.exe", "fcitx5-remote" },
		expected = "im_select",
	},
	{
		name = "WSL custom path",
		wsl = true,
		commands = { "/mnt/c/Tools/im select.exe" },
		command = "/mnt/c/Tools/im select.exe",
		expected = "im_select",
	},
	{ name = "WSL without Windows executable", wsl = true, commands = { "fcitx5-remote" } },
	{ name = "WSL PowerShell fallback", wsl = true, commands = { "powershell.exe" }, expected = "wsl" },
	{
		name = "WSL PowerShell default Windows path",
		wsl = true,
		commands = { "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe" },
		expected = "wsl",
	},
	{
		name = "WSL prefers im-select over PowerShell",
		wsl = true,
		commands = { "im-select.exe", "powershell.exe" },
		expected = "im_select",
	},
	{
		name = "WSL custom PowerShell path",
		wsl = true,
		commands = { "/mnt/d/Windows/powershell.exe" },
		wsl_command = "/mnt/d/Windows/powershell.exe",
		expected = "wsl",
	},
	{
		name = "WSL missing custom PowerShell path",
		wsl = true,
		commands = { "powershell.exe" },
		wsl_command = "/missing/powershell.exe",
	},
	{
		name = "WSL missing custom command does not fall back",
		wsl = true,
		command = "/missing/im-select.exe",
		commands = { "im-select.exe", "fcitx5-remote" },
	},
	{ name = "WSL SSH defaults to Kitty", wsl = true, ssh = true, expected = "kitty" },
	{ name = "WSL Neovide", wsl = true, neovide = true, expected = "neovide" },
	{ name = "WSL explicit Linux driver", wsl = true, driver = "fcitx", expected = "fcitx" },
	{ name = "WSL disabled driver", wsl = true, driver = false },
	{ name = "macOS prefers fcitx", system = "Darwin", commands = { "fcitx5-remote", "macism" }, expected = "fcitx" },
	{
		name = "macOS app path",
		system = "Darwin",
		commands = { "/Library/Input Methods/Fcitx5.app/Contents/bin/fcitx5-remote" },
		expected = "fcitx",
	},
	{ name = "macOS falls back to macism", system = "Darwin", commands = { "macism" }, expected = "macism" },
	{ name = "macOS Homebrew path", system = "Darwin", commands = { "/opt/homebrew/bin/macism" }, expected = "macism" },
	{ name = "macOS without drivers", system = "Darwin" },
	{ name = "Windows default driver", system = "Windows_NT", commands = { "im-select.exe" }, expected = "im_select" },
	{
		name = "Windows custom path",
		system = "Windows_NT",
		commands = { "/custom/im-select.exe" },
		command = "/custom/im-select.exe",
		expected = "im_select",
	},
	{ name = "Windows falls back to winime", system = "Windows_NT", expected = "winime" },
	{
		name = "Windows missing custom command",
		system = "Windows_NT",
		command = "/missing/im-select.exe",
		commands = { "im-select.exe" },
		expected = "winime",
	},
	{ name = "Windows SSH driver", system = "Windows_NT", ssh = true, expected = "kitty" },
	{ name = "Windows Neovide driver", system = "Windows_NT", neovide = true, expected = "neovide" },
	{ name = "unsupported OS", system = "unknown" },
	{ name = "custom SSH driver", ssh = true, custom = true, expected = "test_ssh" },
	{ name = "override Neovide", neovide = true, custom = true, expected = "test_os" },
	{ name = "disable Neovide", neovide = true, custom = true, disabled = true },
	{ name = "disable SSH", ssh = true, custom = true, disabled = true },
	{ name = "custom Windows driver", system = "Windows_NT", custom = true, expected = "winime" },
}

for _, case in ipairs(cases) do
	vim.api.nvim_clear_autocmds({})
	for name in pairs(package.loaded) do
		if name == "imselect" or name:match("^imselect%.") then
			package.loaded[name] = nil
		end
	end
	available = {}
	for _, command in ipairs(case.commands or {}) do
		available[command] = true
	end
	selected, driver_opts, updates = nil, nil, 0
	system = case.system or "Linux"
	wsl = case.wsl or false
	vim.g.neovide = case.neovide or false
	vim.env.SSH_TTY = nil
	vim.env.SSH_CONNECTION = case.ssh and "test connection" or nil
	vim.env.SSH_CLIENT = nil

	local calls = 0
	---@type table<string, any>
	local opts = { driver = case.driver }
	for _, name in ipairs({ "neovide", "kitty", "fcitx", "macism", "test_ssh", "test_os", "im_select", "winime", "wsl" }) do
		opts[name] = { marker = true }
	end
	opts.im_select.command = case.command
	opts.wsl.command = case.wsl_command
	if case.custom then
		opts.driver = function(config)
			assert(config.im_select.command == opts.im_select.command and config.fcitx.marker == true)
			calls = calls + 1
			if case.result == false then
				return false
			end
			if case.disabled then
				return nil
			end
			if require("imselect.util").is_ssh() then
				return "test_ssh"
			end
			return vim.uv.os_uname().sysname == "Windows_NT" and "winime" or "test_os"
		end
	end
	local imselect = require("imselect")
	imselect.setup(opts)
	imselect.setup(opts)
	assert(calls == (case.custom and 1 or 0), case.name .. ": selector runs once")
	assert(selected == case.expected, case.name .. ": selected " .. tostring(selected))
	if case.expected then
		assert(updates == 1, case.name)
		assert(driver_opts, case.name)
		assert(driver_opts.marker == true, case.name)
	else
		assert(
			imselect.driver == nil and updates == 0 and #vim.api.nvim_get_autocmds({ event = "ModeChanged" }) == 0,
			case.name
		)
	end
end
print("driver selection: OK")
