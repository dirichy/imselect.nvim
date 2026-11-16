vim.opt.rtp:prepend(vim.fn.getcwd())

local selected
---@type {tmux_passthrough?: boolean, marker?: boolean}?
local driver_opts
local updates = 0
for _, name in ipairs({ "neovide", "kitty", "test_ssh", "test_os", "im_select" }) do
	package.preload["imselect.driver." .. name] = function()
		return {
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
local function os_uname()
	return { sysname = system }
end
vim.uv.os_uname = os_uname
local cases = {
	{ name = "Neovide over disabled SSH", neovide = true, ssh = true, enable_in_ssh = false, expected = "neovide" },
	{ name = "Neovide over SSH", neovide = true, ssh = true, expected = "neovide" },
	{ name = "local Neovide", neovide = true, expected = "neovide" },
	{ name = "SSH defaults to Kitty", ssh = true, expected = "kitty", passthrough = true },
	{ name = "custom SSH driver", ssh = true, ssh_driver = "test_ssh", expected = "test_ssh" },
	{ name = "explicit passthrough override", ssh = true, passthrough = false, expected = "kitty" },
	{ name = "disabled SSH", ssh = true, enable_in_ssh = false },
	{ name = "Linux driver", system = "Linux", expected = "test_os" },
	{ name = "macOS driver", system = "Darwin", expected = "test_os" },
	{ name = "Windows default driver", system = "Windows_NT", expected = "im_select" },
	{ name = "Windows SSH driver", system = "Windows_NT", ssh = true, expected = "kitty", passthrough = true },
	{ name = "Windows Neovide driver", system = "Windows_NT", neovide = true, expected = "neovide" },
}

for _, case in ipairs(cases) do
	vim.api.nvim_clear_autocmds({})
	for name in pairs(package.loaded) do
		if name == "imselect" or name:match("^imselect%.") then
			package.loaded[name] = nil
		end
	end
	selected, driver_opts, updates = nil, nil, 0
	system = case.system or "Linux"
	vim.g.neovide = case.neovide or false
	vim.env.SSH_TTY = nil
	vim.env.SSH_CONNECTION = case.ssh and "test connection" or nil
	vim.env.SSH_CLIENT = nil

	local opts = {
		default_driver = { Linux = "test_os", Darwin = "test_os", ssh = case.ssh_driver },
		enable_in_ssh = case.enable_in_ssh,
		neovide = { marker = true },
		test_ssh = { marker = true },
		test_os = { marker = true },
		im_select = { marker = true },
		kitty = { tmux_passthrough = case.passthrough },
	}
	require("imselect").setup(opts)
	assert(selected == case.expected, case.name .. ": selected " .. tostring(selected))
	if case.expected then
		assert(updates == 1, case.name)
		assert(driver_opts, case.name)
		if selected == "kitty" then
			assert(driver_opts.tmux_passthrough == case.passthrough, case.name)
		else
			assert(driver_opts.marker == true, case.name)
		end
	else
		assert(updates == 0 and #vim.api.nvim_get_autocmds({ event = "ModeChanged" }) == 0, case.name)
	end
end
print("driver selection: OK")
