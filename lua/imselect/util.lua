local M = {}
function M.is_ssh()
	return vim.env.SSH_TTY
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
return M
