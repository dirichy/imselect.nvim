vim.opt.rtp:prepend(vim.fn.getcwd())

local available = {}
local checked = {}
local function executable(cmd)
	checked[#checked + 1] = cmd
	return available[cmd] and 1 or 0
end
vim.fn.executable = executable
local util = require("imselect.util")

available["custom-im"] = true
assert(util.find_executable({ "custom-im" }) == "custom-im")
available["second-im"] = true
assert(util.find_executable({ "missing-im", "custom-im", "second-im" }) == "custom-im")
assert(vim.deep_equal(checked, { "custom-im", "missing-im", "custom-im" }))
available["/path with spaces/custom-im"] = true
assert(util.find_executable({ "/path with spaces/custom-im" }) == "/path with spaces/custom-im")
local ok, err = pcall(util.find_executable, { "missing-im", "/missing/path" })
assert(not ok and err:find("Can't find executable: missing-im, /missing/path", 1, true), tostring(err))

local system
local function os_uname()
	return { sysname = system }
end
vim.uv.os_uname = os_uname
for _, case in ipairs({
	{ system = "Linux", path = "fcitx-remote", checked = { "fcitx5-remote", "fcitx-remote" } },
	{
		system = "Linux",
		path = "/usr/bin/fcitx5-remote",
		checked = { "fcitx5-remote", "fcitx-remote", "/usr/bin/fcitx5-remote" },
	},
	{
		system = "Darwin",
		path = "/Library/Input Methods/Fcitx5.app/Contents/bin/fcitx5-remote",
		checked = { "fcitx5-remote", "/Library/Input Methods/Fcitx5.app/Contents/bin/fcitx5-remote" },
	},
	{
		system = "Darwin",
		path = "fcitx-remote",
		checked = { "fcitx5-remote", "/Library/Input Methods/Fcitx5.app/Contents/bin/fcitx5-remote", "fcitx-remote" },
	},
	{ system = "Other", path = "fcitx5-remote", checked = { "fcitx5-remote" } },
	{ driver = "macism", system = "Darwin", path = "macism", checked = { "macism" } },
	{
		driver = "macism",
		system = "Darwin",
		path = "/opt/homebrew/bin/macism",
		checked = { "macism", "/opt/homebrew/bin/macism" },
	},
}) do
	system = case.system
	available, checked = { [case.path] = true }, {}
	local module = "imselect.driver." .. (case.driver or "fcitx")
	package.loaded[module] = nil
	require(module).setup({})
	assert(vim.deep_equal(checked, case.checked), vim.inspect(checked))
end
print("executable: OK")
