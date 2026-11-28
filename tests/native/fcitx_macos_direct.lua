-- Run on a macOS desktop with Fcitx selected and active. Changes the input source.
vim.opt.rtp:prepend(vim.fn.getcwd())
local util = require("imselect.util")
local contents = "/Library/Input Methods/Fcitx5.app/Contents/"
local remote = contents .. "bin/fcitx5-remote"
local get_im = contents .. "Resources/get_im"
local switch_im = contents .. "Resources/switch_im"
for _, command in ipairs({ remote, get_im, switch_im }) do
	assert(vim.fn.executable(command) == 1, "Missing Fcitx5 tool: " .. command)
end
local source = util.run({ get_im })
assert(source:match("^org%.fcitx%.inputmethod%.Fcitx5%."), "Select Fcitx5 in macOS before running this test")
assert(util.run({ remote }) == "2", "Activate Fcitx5 before running this test")
local driver = util.with_restore(require("imselect.driver.fcitx_macos_direct").setup({}))
local ok, err = xpcall(function()
	assert(driver.get_state(), "driver did not observe active Fcitx")
	driver.temp_ascii()
	driver.temp_ascii()
	assert(util.run({ remote }) == "1", "Fcitx was not deactivated")
	driver.restore()
	assert(util.run({ remote }) == "2", "Fcitx was not restored")
	-- Selecting another system source must override any active state in the server.
	util.run({ switch_im, "com.apple.keylayout.ABC" })
	assert(util.run({ get_im }) == "com.apple.keylayout.ABC", "could not select ABC")
	assert(not driver.get_state(), "driver ignored the selected system input source")
	util.run({ switch_im, source })
	util.run({ remote, "-o" })
	assert(driver.get_state(), "driver did not observe Fcitx after switching back")
end, debug.traceback)
local cleaned, cleanup_err = pcall(function()
	util.run({ switch_im, source })
	util.run({ remote, "-o" })
end)
assert(ok, err)
assert(cleaned, cleanup_err)
print("fcitx_macos_direct: native state restoration and system input source selection OK")
