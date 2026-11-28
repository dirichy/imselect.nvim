local M = {}
local inspector = require("imselect.inspector")
local util = require("imselect.util")
local prev_cond, prev_mode_ascii
vim.g.imselect_enabled = true
local default_opts = {
	---@type string|false|fun(opts:table):(string|false|nil)
	driver = function(opts)
		if vim.g.neovide then
			return "neovide"
		end
		if util.is_ssh() then
			return "kitty"
		end
		local system = vim.uv.os_uname().sysname
		if system == "Linux" and vim.fn.has("wsl") == 1 then
			system = "WSL"
		end
		local candidates = {
			Linux = { "fcitx" },
			WSL = { "im_select", "wsl" },
			Darwin = { "fcitx", "macism" },
			Windows_NT = { "im_select" },
		}
		for _, name in ipairs(candidates[system] or {}) do
			if pcall(require("imselect.driver." .. name).find_command, opts[name] or {}) then
				return name
			end
		end
		if system == "Windows_NT" then
			return "winime"
		end
	end,
	focus_event = false,
	---@type Imselect.Inspector?
	inspector = nil,
}

M.set_inspector = inspector.set
--- to determine whether to enable im
--- this function will be called rapidly so it can't be too heavy.
--- @return boolean
function M.inspect()
	local buffer = vim.api.nvim_win_get_buf(0)
	return inspector.inspect(buffer)
end

local function update_driver(force)
	local mode = vim.api.nvim_get_mode().mode
	local cmdtype = vim.fn.getcmdtype()
	local search = cmdtype == "/" or cmdtype == "?"
	-- ic (completion) and ix (CTRL-X) still use the Insert cursor policy.
	local mode_ascii = mode:sub(1, 1) ~= "i" and not search
	local new_state = search or (not mode_ascii and M.inspect())
	-- When mode change into ascii, we should force to call driver no matter if state changed.
	local mode_change_into_ascii = mode_ascii and prev_mode_ascii == false
	if not force and new_state == prev_cond and not mode_change_into_ascii then
		prev_mode_ascii = mode_ascii
		return
	end

	if new_state then
		M.driver.restore()
	else
		M.driver.temp_ascii()
	end
	prev_cond, prev_mode_ascii = new_state, mode_ascii
end

M.update = function(force)
	if not vim.g.imselect_enabled then
		return
	end

	update_driver(force)
end

M.setup = util.once(function(opts)
	opts = opts or {}
	opts = vim.tbl_deep_extend("force", default_opts, opts)
	local driver_name = opts.driver
	if type(driver_name) == "function" then
		driver_name = driver_name(opts)
	end
	if not driver_name then
		return
	end
	if opts.inspector ~= nil then
		M.set_inspector(opts.inspector)
	end
	---@type Imselect.Driver
	M.driver = util.with_restore(require("imselect.driver." .. driver_name).setup(opts[driver_name] or {}))
	M.update(true)
	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		callback = function()
			vim.schedule(function()
				M.update()
			end)
		end,
	})
	vim.api.nvim_create_autocmd({ "FileType" }, {
		callback = function()
			vim.schedule(function()
				M.update(true)
			end)
		end,
	})
	vim.api.nvim_create_autocmd({ "ModeChanged", "CursorMovedI", "TextChangedI" }, {
		callback = function()
			vim.schedule(function()
				M.update()
			end)
		end,
	})
	if opts.focus_event then
		vim.api.nvim_create_autocmd({ "FocusGained" }, {
			callback = function()
				vim.schedule(function()
					M.update(true)
				end)
			end,
		})
		vim.api.nvim_create_autocmd("FocusLost", {
			callback = function()
				M.driver.restore()
			end,
		})
	end

	vim.api.nvim_create_autocmd({ "User" }, {
		pattern = { "LuasnipInsertNodeEnter", "LuasnipInsertNodeLeave" },
		callback = function()
			vim.schedule(function()
				M.update()
			end)
		end,
	})
end)

return M
