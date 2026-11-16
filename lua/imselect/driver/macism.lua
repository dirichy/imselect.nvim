local util = require("imselect.util")
local M = {}
M.ascii_state = "com.apple.keylayout.ABC"
local cmd
M.setup = util.once(function(opts)
	cmd = util.find_executable({ "macism", "/opt/homebrew/bin/macism" })
	M.ascii_state = opts.ascii or M.ascii_state
	return M
end)

M.set_state = function(state)
	local result = vim.system({ cmd, state }):wait()
	if result.code ~= 0 then
		error("imselect: macism could not set the input source")
	end
end
M.get_state = function(callback)
	if not callback then
		local result = vim.system({ cmd }):wait()
		local state = vim.trim(result.stdout or "")
		if result.code ~= 0 or state == "" then
			error("imselect: macism could not query the input source")
		end
		return state
	end
	return vim.system({ cmd }, {}, function(obj)
		local state = vim.trim(obj.stdout or "")
		return callback(obj.code == 0 and state ~= "" and state or nil)
	end)
end
return M
