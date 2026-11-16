vim.opt.rtp:prepend(vim.fn.getcwd())
local util = require("imselect.util")
local function command(script)
	return { vim.v.progpath, "--headless", "-u", "NONE", "-i", "NONE", "-c", script }
end

local success = command([[lua io.stdout:write(" \tvalue\r\n "); vim.cmd("qa!")]])
local failure = command([[lua io.stderr:write(" broken \n"); vim.cmd("cquit 7")]])
assert(util.run(success) == "value")
assert(util.run(command("qa!")) == "", "empty stdout is valid for setter commands")
local ok, err = pcall(util.run, failure)
assert(not ok and type(err) == "string", tostring(err))
assert(err:find("exit 7", 1, true) and err:find("broken", 1, true), err)

local finished = false
local output, failure_message
local process = util.run(success, function(value, message)
	output, failure_message, finished = value, message, true
end)
assert(type(process.wait) == "function")
assert(vim.wait(2000, function()
	return finished
end))
assert(output == "value" and failure_message == nil)

finished = false
util.run(failure, function(value, message)
	output, failure_message, finished = value, message, true
end)
assert(vim.wait(2000, function()
	return finished
end))
assert(type(failure_message) == "string")
assert(output == nil and failure_message:find("exit 7", 1, true) and failure_message:find("broken", 1, true))

ok, err = pcall(util.run, command([[lua vim.uv.sleep(2000); vim.cmd("qa!")]]))
assert(not ok and type(err) == "string", tostring(err))
assert(err:find("exit 124", 1, true), err)
print("run: OK")
