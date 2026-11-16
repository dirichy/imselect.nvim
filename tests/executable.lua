vim.opt.rtp:prepend(vim.fn.getcwd())

local system = "Linux"
vim.uv.os_uname = function()
	return { sysname = system }
end
local available = {}
local function executable(cmd)
	return available[cmd] and 1 or 0
end
vim.fn.executable = executable
local util = require("imselect.util")

available["fcitx-remote"] = true
assert(util.find_executable("fcitx5-remote") == "fcitx-remote")
available["fcitx5-remote"] = true
assert(util.find_executable("fcitx5-remote") == "fcitx5-remote")

system = "Darwin"
available = { ["/opt/homebrew/bin/macism"] = true }
assert(util.find_executable("macism") == "/opt/homebrew/bin/macism")
available = {}
local ok, err = pcall(util.find_executable, "macism")
assert(not ok and err:find("Can't find executable macism", 1, true), tostring(err))

available["custom-im"] = true
assert(util.find_executable("custom-im") == "custom-im")
ok, err = pcall(util.find_executable, "missing-im")
assert(not ok and err:find("Can't find executable missing-im", 1, true), tostring(err))
print("executable: OK")
