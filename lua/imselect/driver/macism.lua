local util = require("imselect.util")
local M = {}
M.ascii_state = "com.apple.keylayout.ABC"
local cmd
function M.find_command()
	return util.find_executable({ "macism", "/opt/homebrew/bin/macism" })
end

M.setup = util.once(function(opts)
	cmd = M.find_command()
	M.ascii_state = opts.ascii or M.ascii_state
	return M
end)

M.set_state = function(state)
	util.run({ cmd, state })
end
M.get_state = function(callback)
	if not callback then
		local state = util.run({ cmd })
		if state == "" then
			error("imselect: macism could not query the input source")
		end
		return state
	end
	return util.run({ cmd }, function(state, err)
		return callback(state ~= "" and state or nil, err)
	end)
end
return M
