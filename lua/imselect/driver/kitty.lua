---@type Imselect.Driver
local M = {}

local function osc_set_user_var(key, value)
	local encoded = vim.base64.encode(value)
	vim.api.nvim_ui_send(("\027]1337;SetUserVar=%s=%s\007"):format(key, encoded))
end

local function send_im(value)
	osc_set_user_var("im", value)
end

M.setup = function(opts)
	return M
end

M.restore = function()
	send_im("restore")
end

M.temp_ascii = function()
	send_im("temp_ascii")
end

return M
