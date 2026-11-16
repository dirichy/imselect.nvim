local util = require("imselect.util")
local ffi = require("ffi")
local M = {}
M.ascii_state = false
local user32
local imm32

M.setup = util.once(function()
	if ffi.os ~= "Windows" then
		error("imselect: winime requires native Windows Neovim with LuaJIT")
	end
	ffi.cdef([[
		typedef struct {
			uint32_t cbSize, flags;
			void *hwndActive, *hwndFocus, *hwndCapture;
			void *hwndMenuOwner, *hwndMoveSize, *hwndCaret;
			int32_t rcCaret[4];
		} ImselectGUIThreadInfo;
		int __stdcall GetGUIThreadInfo(uint32_t thread, ImselectGUIThreadInfo *info);
		void *__stdcall ImmGetDefaultIMEWnd(void *window);
		intptr_t __stdcall SendMessageTimeoutW(void *window, uint32_t message,
			uintptr_t command, intptr_t value, uint32_t flags, uint32_t timeout,
			uintptr_t *result);
	]])
	user32 = ffi.load("user32")
	imm32 = ffi.load("imm32")
	return M
end)

local function control(command, value)
	---@class Imselect.GUIThreadInfo: ffi.cdata*
	---@field cbSize number
	---@field hwndActive ffi.cdata*
	---@field hwndFocus ffi.cdata*
	local info = ffi.new("ImselectGUIThreadInfo")
	info.cbSize = assert(ffi.sizeof(info))
	if user32.GetGUIThreadInfo(0, info) == 0 then
		error("imselect: cannot query the foreground GUI thread")
	end
	local window = info.hwndFocus
	if window == nil then
		window = info.hwndActive
	end
	if window == nil then
		error("imselect: no foreground input window")
	end
	local ime = imm32.ImmGetDefaultIMEWnd(window)
	if ime == nil then
		error("imselect: no IME window for the foreground input window")
	end
	local result = ffi.new("uintptr_t[1]")
	-- WM_IME_CONTROL, SMTO_ABORTIFHUNG | SMTO_ERRORONEXIT, 100 ms delivery timeout.
	if user32.SendMessageTimeoutW(ime, 0x0283, command, value or 0, 0x0022, 100, result) == 0 then
		error("imselect: IME control failed or timed out")
	end
	return tonumber(result[0])
end

function M.get_state()
	return control(0x0005) ~= 0 -- IMC_GETOPENSTATUS
end

function M.set_state(state)
	control(0x0006, state and 1 or 0) -- IMC_SETOPENSTATUS
end

return M
