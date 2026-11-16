local util = require("imselect.util")
local M = {}
local command

function M.find_command(opts)
	return util.find_executable({ opts.command or "im-select.exe" })
end

M.setup = util.once(function(opts)
	command = M.find_command(opts)
	M.ascii_state = tostring(opts.ascii or "1033")
	return M
end)

function M.get_state()
	local current = util.run({ command })
	if not current:match("^%d+$") then
		error("imselect: im-select returned an invalid layout ID: " .. current)
	end
	return current
end

function M.set_state(state)
	util.run({ command, state })
end

return M
