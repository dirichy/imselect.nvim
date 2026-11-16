vim.opt.rtp:prepend(vim.fn.getcwd())
vim.env.SSH_TTY = nil
vim.env.SSH_CLIENT = nil
vim.env.TMUX = "test tmux"
local sent = {}
vim.api.nvim_ui_send = function(value)
	sent[#sent + 1] = value
end

for _, case in ipairs({
	{ ssh = false, wrapped = false },
	{ ssh = true, wrapped = true },
	{ ssh = true, passthrough = false, wrapped = false },
	{ ssh = false, passthrough = true, wrapped = true },
}) do
	package.loaded["imselect.driver.kitty"] = nil
	vim.env.SSH_CONNECTION = case.ssh and "test connection" or nil
	sent = {}
	local driver = require("imselect.driver.kitty").setup({ tmux_passthrough = case.passthrough })
	driver.temp_ascii()
	driver.restore()
	assert(#sent == 3)
	for i, value in ipairs({ "reset", "temp_ascii", "restore" }) do
		local osc = "\027]1337;SetUserVar=im=" .. vim.base64.encode(value) .. "\027\\"
		if case.wrapped then
			osc = "\027Ptmux;" .. osc:gsub("\027", "\027\027") .. "\027\\"
		end
		assert(sent[i] == osc)
	end
end
print("kitty: OK")
