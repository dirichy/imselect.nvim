local util = require("imselect.util")
---@type Imselect.Driver
local M = {}
M.ascii_state = false
local fcitx_remote
local candidates = {
	Darwin = { "fcitx5-remote", "/Library/Input Methods/Fcitx5.app/Contents/bin/fcitx5-remote", "fcitx-remote" },
	Linux = { "fcitx5-remote", "fcitx-remote", "/usr/bin/fcitx5-remote" },
}

M.setup = util.once(function(opts)
	fcitx_remote = util.find_executable(candidates[vim.uv.os_uname().sysname] or { "fcitx5-remote" })
	return M
end)
M.set_state = function(state)
	util.run({ fcitx_remote, state and "-o" or "-c" })
end
---@param callback? fun(state:boolean?,err:string?) Optional asynchronous query.
---@return boolean
---@overload fun(callback:fun(state:boolean?,err:string?)):vim.SystemObj
function M.get_state(callback)
	if not callback then
		return util.run({ fcitx_remote }) == "2"
	end
	return util.run({ fcitx_remote }, function(output, err)
		if output == nil then
			return callback(nil, err)
		end
		return callback(output == "2")
	end)
end
return M
