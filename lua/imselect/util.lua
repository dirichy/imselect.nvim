local M = {}
function M.is_ssh()
	return vim.env.SSH_TTY or vim.env.SSH_CONNECTION or vim.env.SSH_CLIENT
end

local executable_table = {
	["fcitx5-remote"] = {
		Darwin = { "fcitx5-remote", "/Library/Input Methods/Fcitx5.app/Contents/bin/fcitx5-remote", "fcitx-remote" },
		Linux = { "fcitx5-remote", "fcitx-remote", "/usr/bin/fcitx5-remote" },
	},
	macism = {
		Darwin = { "macism", "/opt/homebrew/bin/macism" },
	},
}
function M.find_executable(cmd)
	local system = vim.uv.os_uname().sysname
	if executable_table[cmd] then
		if executable_table[cmd][system] then
			for _, path in ipairs(executable_table[cmd][system]) do
				if vim.fn.executable(path) then
					return path
				end
			end
			error("Can't find executable " .. cmd)
		end
	end
	if vim.fn.executable(cmd) then
		return cmd
	else
		error("Can't find executable " .. cmd)
	end
end
--- only execute fn once
---@param fn function
---@return function
function M.once(fn)
	local called = nil
	return function(...)
		if called ~= nil then
			return called
		else
			called = fn(...)
			return called
		end
	end
end

function M.with_restore(driver)
	if driver.temp_ascii and driver.restore then
		return driver
	end

	local saved_state = nil
	driver.temp_ascii = function()
		if saved_state ~= nil then
			return
		end
		saved_state = driver.is_active()
		if saved_state then
			driver.disable()
		end
	end
	driver.restore = function()
		if saved_state == nil then
			return
		end
		if saved_state then
			driver.active()
		else
			driver.disable()
		end
		saved_state = nil
	end
	return driver
end

return M
