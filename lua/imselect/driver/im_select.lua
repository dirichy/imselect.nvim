local util = require("imselect.util")
local M = {}
local command

local function run(value)
	local args = { command }
	if value then
		args[2] = value
	end
	local result = vim.system(args, { timeout = 1000 }):wait()
	if result.code ~= 0 then
		error(("imselect: %s failed: %s"):format(command, vim.trim(result.stderr or "")))
	end
	return vim.trim(result.stdout or "")
end

M.setup = util.once(function(opts)
	command = util.find_executable({ opts.command or "im-select.exe" })
	M.ascii_state = tostring(opts.ascii or "1033")
	return M
end)

function M.get_state()
	local current = run()
	if not current:match("^%d+$") then
		error("imselect: im-select returned an invalid layout ID: " .. current)
	end
	return current
end

function M.set_state(state)
	run(state)
end

return M
