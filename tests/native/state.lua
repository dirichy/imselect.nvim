-- Run inside a real terminal. The observer uses OS tools, never driver.get_state().
vim.defer_fn(function()
	local name = assert(vim.env.IMSELECT_TEST_DRIVER, "IMSELECT_TEST_DRIVER is required")
	local observer = vim.json.decode((assert(vim.env.IMSELECT_TEST_OBSERVER, "observer command is required")))
	local function observe(action)
		local args = vim.list_extend(vim.deepcopy(observer), { action or "get" })
		local result = vim.system(args, { text = true, timeout = 15000 }):wait()
		assert(result.code == 0 and result.signal == 0, "observer failed: " .. vim.inspect(result))
		return vim.trim(result.stdout)
	end
	local driver, original
	local function wait_state(expected)
		assert(
			vim.wait(15000, function()
				return observe() == expected
			end, 200),
			"expected input state: " .. expected
		)
	end
	local ok, err = pcall(function()
		vim.opt.rtp:prepend(vim.fn.getcwd())
		original = observe("prepare")
		driver = require("imselect.util").with_restore(require("imselect.driver." .. name).setup({
			command = vim.env.IMSELECT_TEST_COMMAND,
		}))
		local ascii = name == "wsl" and "0:0" or tostring(driver.ascii_state)
		assert(original ~= "" and original ~= ascii, "fixture did not select a non-ASCII input method: " .. original)
		driver.temp_ascii()
		wait_state(ascii)
		driver.temp_ascii()
		wait_state(ascii)
		driver.restore()
		wait_state(original)
	end)
	-- Best-effort cleanup even when an assertion fails; preserve the original failure.
	if driver and original then
		pcall(function()
			driver.restore()
			wait_state(original)
		end)
	end
	vim.fn.writefile(
		{ vim.json.encode({ driver = name, passed = ok, error = ok and vim.NIL or tostring(err) }) },
		assert(vim.env.IMSELECT_TEST_REPORT)
	)
	if not ok then
		io.stderr:write(tostring(err) .. "\n")
	end
	vim.cmd(ok and "qa!" or "cquit 1")
end, 1000)
