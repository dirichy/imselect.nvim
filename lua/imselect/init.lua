local M = {}
local strategy = require("imselect.strategy.init")
local system = vim.uv.os_uname().sysname
local util = require("imselect.util")
local cur_state
local prev_cond
vim.g.imselect_enabled = true
local default_opts = {
	default_driver = {
		Darwin = "fcitx",
		Linux = "fcitx",
	},
	strategy = {
		strategy = { require("imselect.strategy.nvimtex"), require("imselect.strategy.default") },
		strategy_provider = {
			nvimtex = { filetype = { "tex", "latex" } },
			default = {
				inspecter = function()
					return true
				end,
			},
		},
	},
}

local im_state = {
	-- english no matter what cirrumstance
	perm_ascii = 0,
	-- users use another (like chinese), but nvim state determines the im should be english (like in normal mode of nvim).
	temp_ascii = 1,
	-- im is not english actually now.
	none_ascii = 2,
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
	return inspecters[buffer](buffer)
end

local function inspect_changed()
	local cur_cond = M.inspect()
	if cur_cond == prev_cond then
		return false, false
	end
	prev_cond = cur_cond
	return true, cur_cond
end

local function if_user_changed_im()
	-- judge if the user changes the im mamually.
	local actual_state = M.driver.is_active()
	local state_if_user_not_change_im = cur_state == im_state.none_ascii
	return actual_state ~= state_if_user_not_change_im, actual_state
end

M.update = function()
	if not vim.g.imselect_enabled then
		return
	end
	local flag, new_state = inspect_changed()
	if not flag then
		return
	end
	local user_changed_im, user_change_state = if_user_changed_im()
	if user_changed_im then
		cur_state = user_change_state and im_state.none_ascii or im_state.perm_ascii
	end

	if new_state then
		if cur_state == im_state.temp_ascii then
			M.driver.active()
			cur_state = im_state.none_ascii
		end
	else
		if cur_state == im_state.none_ascii then
			M.driver.disable()
			cur_state = im_state.temp_ascii
		end
	end
end

M.setup = util.once(function(opts)
	opts = vim.tbl_deep_extend("force", default_opts, opts)
	if util.is_ssh() then
		return
	end
	if vim.g.neovide then
		---@type Imselect.Driver
		M.driver = require("imselect.driver.neovide").setup(opts.neovide or {})
	else
		if opts.default_driver[system] then
			---@type Imselect.Driver
			M.driver = require("imselect.driver." .. opts.default_driver[system]).setup(
				opts[opts.default_driver[system]] or {}
			)
		else
			error("Imselect don't support " .. system)
		end
	end
	strategy.apply(vim.api.nvim_win_get_buf(0))
	M.driver.is_active(function(result)
		cur_state = result and im_state.none_ascii or im_state.perm_ascii
		vim.schedule(M.update)
	end)
	prev_cond = M.inspect()
	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		callback = function(event)
			local buffer = event.buf
			if not inspecters[buffer] then
				strategy.apply(buffer)
			end
		end,
	})
	vim.api.nvim_create_autocmd({ "ModeChanged" }, {
		callback = function()
			vim.schedule(function()
				M.update()
			end)
		end,
	})
	vim.api.nvim_create_autocmd({ "CursorMovedI" }, {
		callback = function()
			vim.schedule(function()
				M.update()
			end)
		end,
	})

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
