local util = require("imselect.util")
local ffi = require("ffi")
local M = { ascii_state = false }

M.setup = util.once(function()
	if ffi.os ~= "OSX" then
		error("imselect: fcitx_macos_direct requires macOS Neovim with LuaJIT")
	end
	ffi.cdef([[
		void *TISCopyCurrentKeyboardInputSource(void);
		void *TISGetInputSourceProperty(void *source, const void *key);
		extern const void *kTISPropertyInputSourceID;
		void CFRelease(const void *object);
		const void *CFStringCreateWithCString(const void *allocator, const char *string, uint32_t encoding);
		unsigned char CFStringHasPrefix(const void *string, const void *prefix);
		void *curl_easy_init(void);
		void curl_easy_cleanup(void *handle);
		int curl_easy_setopt(void *handle, int option, ...);
		int curl_easy_perform(void *handle);
		int curl_easy_getinfo(void *handle, int info, ...);
		const char *curl_easy_strerror(int code);
	]])
	local carbon = ffi.load("/System/Library/Frameworks/Carbon.framework/Carbon")
	local cf = ffi.load("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation")
	local curl = ffi.load("/usr/lib/libcurl.4.dylib")
	local prefix = cf.CFStringCreateWithCString(nil, "org.fcitx.inputmethod.Fcitx5.", 0x08000100) -- UTF-8
	assert(prefix ~= nil, "imselect: cannot create Fcitx input source prefix")
	prefix = ffi.gc(prefix, cf.CFRelease)

	-- Match fcitx5-curl's config location and defaults; read once per Neovim session.
	local config = {}
	local path = vim.env.HOME .. "/.config/fcitx5/conf/beast.conf"
	local file, err, errno = io.open(path, "r")
	if file then
		for line in file:lines() do
			local key, value = line:match("^(%w+)=(.-)\r?$")
			if key and value ~= "" then
				config[key] = value
			end
		end
		file:close()
	elseif errno ~= 2 then -- ENOENT: missing config uses upstream defaults.
		error("imselect: cannot read Beast config: " .. tostring(err))
	end
	local base = config.Communication == "TCP" and ("http://127.0.0.1:" .. (config.Port or "32489")) or "http://fcitx"
	local response = ""
	---@class Imselect.CurlCallback: ffi.cdata*
	---@field free fun(self:Imselect.CurlCallback)
	local write = ffi.cast("size_t (*)(char *, size_t, size_t, void *)", function(data, size, count)
		local length = tonumber(size * count)
		-- These endpoints return at most a state number or an empty body.
		if #response + length > 4096 then
			return 0
		end
		response = response .. ffi.string(data, length)
		return length
	end)
	local handle = curl.curl_easy_init()
	if handle == nil then
		write:free()
		error("imselect: cannot initialize libcurl")
	end
	handle = ffi.gc(handle, function(value)
		curl.curl_easy_cleanup(value)
		write:free()
	end)
	local function check(code)
		if code ~= 0 then
			error("imselect: Fcitx HTTP: " .. ffi.string(curl.curl_easy_strerror(code)))
		end
	end
	check(curl.curl_easy_setopt(handle, 47, ffi.new("long", 1))) -- CURLOPT_POST
	check(curl.curl_easy_setopt(handle, 60, ffi.new("long", 0))) -- CURLOPT_POSTFIELDSIZE
	check(curl.curl_easy_setopt(handle, 99, ffi.new("long", 1))) -- CURLOPT_NOSIGNAL
	check(curl.curl_easy_setopt(handle, 155, ffi.new("long", 1000))) -- CURLOPT_TIMEOUT_MS
	check(curl.curl_easy_setopt(handle, 10004, "")) -- CURLOPT_PROXY: local IPC must bypass proxies.
	check(curl.curl_easy_setopt(handle, 20011, write)) -- CURLOPT_WRITEFUNCTION
	if config.Communication ~= "TCP" then
		check(curl.curl_easy_setopt(handle, 10231, config.Path or "/tmp/fcitx5.sock")) -- CURLOPT_UNIX_SOCKET_PATH
	end

	local function request(command)
		response = ""
		check(curl.curl_easy_setopt(handle, 10002, base .. "/remote/" .. command)) -- CURLOPT_URL
		check(curl.curl_easy_perform(handle))
		local status = ffi.new("long[1]")
		check(curl.curl_easy_getinfo(handle, 0x200002, status)) -- CURLINFO_RESPONSE_CODE
		if status[0] ~= 200 then
			error("imselect: Fcitx HTTP " .. tonumber(status[0]) .. ": " .. vim.trim(response))
		end
		return vim.trim(response)
	end
	-- libcurl invokes a Lua callback; keep its calling frame out of JIT traces.
	jit.off(request, true)

	function M.get_state()
		local source = carbon.TISCopyCurrentKeyboardInputSource()
		if source == nil then
			error("imselect: cannot query the current macOS input source")
		end
		local id = carbon.TISGetInputSourceProperty(source, carbon.kTISPropertyInputSourceID)
		-- Upstream get_im falls back to a Fcitx ID if the property is absent.
		local active = id == nil or cf.CFStringHasPrefix(id, prefix) ~= 0
		cf.CFRelease(source)
		if not active then
			return false
		end
		local state = request("")
		if state ~= "0" and state ~= "1" and state ~= "2" then
			error("imselect: invalid Fcitx HTTP state: " .. state)
		end
		return state == "2"
	end

	function M.set_state(state)
		request(state and "o" or "c")
	end
	return M
end)

return M
