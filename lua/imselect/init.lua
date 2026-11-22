local M = {}
local strategy = require("imselect.strategy.init")
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
		local candidates = {
			Linux = { "fcitx" },
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
}

---@type table<number,function>
local inspecters = {}
--- set inspecter for a buffer
---@param buffer number
---@param fn function
function M.set_inspecter(buffer, fn)
	inspecters[buffer] = fn
	return true
end
--- to determine whether to enable im
--- this function will be called rapidly so it can't be too heavy.
--- @return boolean
function M.inspect()
	local buffer = vim.api.nvim_win_get_buf(0)
	return inspecters[buffer] and inspecters[buffer](buffer)
end

local function apply_buffer_strategy(buffer)
	inspecters[buffer] = nil
	strategy.apply(buffer)
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
	strategy.setup(opts.strategy or {})
	---@type Imselect.Driver
	M.driver = util.with_restore(require("imselect.driver." .. driver_name).setup(opts[driver_name] or {}))
	apply_buffer_strategy(vim.api.nvim_win_get_buf(0))
	M.update(true)
	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		callback = function(event)
			local buffer = event.buf
			if not inspecters[buffer] then
				strategy.apply(buffer)
			end
			vim.schedule(function()
				M.update()
			end)
		end,
	})
	vim.api.nvim_create_autocmd({ "FileType" }, {
		callback = function(event)
			apply_buffer_strategy(event.buf)
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
