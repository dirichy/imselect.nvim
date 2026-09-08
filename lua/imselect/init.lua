local M = {}
local strategy = require("imselect.strategy.init")
local system = vim.uv.os_uname().sysname
local util = require("imselect.util")
local prev_cond
vim.g.imselect_enabled = true
local default_opts = {
	default_driver = {
		Darwin = "fcitx",
		Linux = "fcitx",
		ssh = "kitty",
	},
	strategy = {
		strategy = { require("imselect.strategy.nvimtex"), require("imselect.strategy.default") },
		strategy_provider = {
			nvimtex = { filetype = { "tex", "latex" } },
		},
	},
	focus_event = false,
	enable_in_ssh = true,
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

local function inspect_changed()
	local cur_cond = M.inspect()
	if cur_cond == prev_cond then
		return false, false
	end
	prev_cond = cur_cond
	return true, cur_cond
end

local function apply_buffer_strategy(buffer)
	inspecters[buffer] = nil
	strategy.apply(buffer)
end

local function update_driver(force)
	local flag, new_state
	if force then
		flag = true
		new_state = M.inspect()
		prev_cond = new_state
	else
		flag, new_state = inspect_changed()
	end
	if not flag then
		return
	end

	if new_state then
		M.driver.restore()
	else
		M.driver.temp_ascii()
	end
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
	local driver_name = opts.default_driver[system]
	if util.is_ssh() then
		if opts.enable_in_ssh then
			driver_name = opts.default_driver.ssh
			opts.enable_in_ssh = true
			opts.kitty = vim.tbl_deep_extend("force", { tmux_passthrough = true }, opts.kitty or {})
		else
			return
		end
	end
	strategy.setup(opts.strategy or {})
	if vim.g.neovide then
		---@type Imselect.Driver
		M.driver = util.with_restore(require("imselect.driver.neovide").setup(opts.neovide or {}))
	else
		if driver_name then
			---@type Imselect.Driver
			M.driver = util.with_restore(require("imselect.driver." .. driver_name).setup(opts[driver_name] or {}))
		else
			vim.notify("Imselect don't support " .. system, vim.log.levels.WARN)
		end
	end
	apply_buffer_strategy(vim.api.nvim_win_get_buf(0))
	M.update(true)
	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		callback = function(event)
			local buffer = event.buf
			if not inspecters[buffer] then
				strategy.apply(buffer)
			end
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
	vim.api.nvim_create_autocmd({ "ModeChanged", "CursorMovedI" }, {
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
