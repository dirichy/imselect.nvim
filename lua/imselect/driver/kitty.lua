---@type Imselect.Driver
local M = {}
local default_opts = {
	tmux_passthrough = false,
}
local opts = default_opts

local function osc_set_user_var(key, value)
	local encoded = vim.base64.encode(value)
	local osc = ("\027]1337;SetUserVar=%s=%s\027\\"):format(key, encoded)
	if opts.tmux_passthrough and vim.env.TMUX then
		osc = ("\027Ptmux;%s\027\\"):format(osc:gsub("\027", "\027\027"))
	end
	vim.api.nvim_ui_send(osc)
end

local function send_im(value)
	osc_set_user_var("im", value)
end

M.setup = function(user_opts)
	opts = vim.tbl_deep_extend("force", default_opts, user_opts or {})
	send_im("reset")
	return M
end

M.restore = function()
	send_im("restore")
end

M.temp_ascii = function()
	send_im("temp_ascii")
end

return M
