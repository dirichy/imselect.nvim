local util = require("imselect.util")
local M = {}
local im_table = {
	active = "org.fcitx.inputmethod.Fcitx5.zhHans",
	disable = "com.apple.keylayout.ABC",
}
local cmd
M.setup = util.once(function(opts)
	cmd = util.find_executable("macism")
	for key, value in pairs(im_table) do
		im_table[value] = key
	end
	return M
end)

M.active = function()
	vim.system({ cmd, im_table.zh }):wait()
end
M.disable = function()
	vim.system({ cmd, im_table.en }):wait()
end
M.is_active = function()
	local im = vim.system({ cmd }):wait().stdout
	if not im then
		return false
	end
	im = im:gsub("%s+", "")
	return im_table[im] == "active"
end
return M
