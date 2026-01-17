local util = require("imselect.util")
---@type Imselect.Driver
local M = {}
local fcitx_remote

M.setup = util.once(function(opts)
	fcitx_remote = util.find_executable("fcitx5-remote")
	return M
end)
M.active = function()
	vim.system({ fcitx_remote, "-o" }):wait()
end
M.disable = function()
	vim.system({ fcitx_remote, "-c" }):wait()
end
---@return boolean
function M.is_active()
	local output = vim.system({ fcitx_remote }):wait().stdout or ""
	output = string.gsub(output, "%s", "")
	return output == "2"
end
return M
