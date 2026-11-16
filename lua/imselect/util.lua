local M = {}
function M.is_ssh()
	return vim.env.SSH_TTY or vim.env.SSH_CONNECTION or vim.env.SSH_CLIENT
end

---@param candidates string[] Command names or paths, in preference order.
---@return string
function M.find_executable(candidates)
	for _, path in ipairs(candidates) do
		if vim.fn.executable(path) == 1 then
			return path
		end
	end
	error("Can't find executable: " .. table.concat(candidates, ", "))
end
--- only execute fn once
---@param fn function
---@return function
function M.once(fn)
	local called = false
	local result
	return function(...)
		if not called then
			result = fn(...)
			called = true
		end
		return result
	end
end

function M.with_restore(driver)
	if driver.temp_ascii and driver.restore then
		return driver
	end

	local saved_state = nil
	driver.temp_ascii = function()
		if saved_state ~= nil then
			return
		end
		local state = driver.get_state()
		if state == nil then
			error("imselect: driver returned no input state")
		end
		saved_state = state
		if state ~= driver.ascii_state then
			driver.set_state(driver.ascii_state)
		end
	end
	driver.restore = function()
		if saved_state == nil then
			return
		end
		driver.set_state(saved_state)
		saved_state = nil
	end
	return driver
end

return M
