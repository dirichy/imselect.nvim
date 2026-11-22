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

---@param args string[]
---@param callback? nil
---@return string Trimmed stdout; command failures raise an error.
---@overload fun(args:string[],callback:fun(output:string?,err:string?)):vim.SystemObj
function M.run(args, callback)
	local function finish(result)
		local output, err
		if result.code ~= 0 or (result.signal or 0) ~= 0 then
			err = ("imselect: %s failed (exit %s, signal %s): %s"):format(
				args[1],
				result.code,
				result.signal or 0,
				vim.trim(result.stderr or "")
			)
		else
			output = vim.trim(result.stdout or "")
		end
		if callback then
			return callback(output, err)
		end
		if err then
			error(err)
		end
		return output
	end
	local opts = { timeout = 1000 }
	if callback then
		return vim.system(args, opts, finish)
	end
	return finish(vim.system(args, opts):wait())
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
		local state = driver.get_state()
		if state == nil then
			error("imselect: driver returned no input state")
		end
		-- Non-ASCII while temporarily ASCII means the user selected a new input state.
		if saved_state == nil or state ~= driver.ascii_state then
			saved_state = state
		end
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
