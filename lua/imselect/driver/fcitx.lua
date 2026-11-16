local util = require("imselect.util")
---@type Imselect.Driver
local M = {}
M.ascii_state = false
local fcitx_remote

M.setup = util.once(function(opts)
	fcitx_remote = util.find_executable("fcitx5-remote")
	return M
end)
M.set_state = function(state)
	vim.system({ fcitx_remote, state and "-o" or "-c" }):wait()
end
---@param callback nil if set, will run async and use callback for vim.system
---@return boolean
---@overload fun(callback:fun(result:boolean)):vim.SystemObj
function M.get_state(callback)
	if not callback then
		local output = vim.system({ fcitx_remote }):wait().stdout or ""
		output = string.gsub(output, "%s", "")
		return output == "2"
	end
	return vim.system({ fcitx_remote }, {}, function(result)
		local output = result.stdout or ""
		output = string.gsub(output, "%s", "")
		return callback(output == "2")
	end)
end
return M
