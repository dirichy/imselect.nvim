local util = require("imselect.util")
local ffi = require("ffi")
local M = { ascii_state = false }
local dbus, connection

M.setup = util.once(function()
	if ffi.os ~= "Linux" then
		error("imselect: dbus requires Linux Neovim with LuaJIT and libdbus-1")
	end
	ffi.cdef([[
		typedef struct DBusConnection DBusConnection;
		typedef struct DBusMessage DBusMessage;
		typedef struct {
			const char *name, *message;
			unsigned int dummy1:1, dummy2:1, dummy3:1, dummy4:1, dummy5:1;
			void *padding1;
		} ImselectDBusError;
		void dbus_error_init(ImselectDBusError *error);
		void dbus_error_free(ImselectDBusError *error);
		DBusConnection *dbus_bus_get_private(int type, ImselectDBusError *error);
		void dbus_connection_set_exit_on_disconnect(DBusConnection *connection, unsigned int enabled);
		unsigned int dbus_connection_get_is_connected(DBusConnection *connection);
		void dbus_connection_close(DBusConnection *connection);
		void dbus_connection_unref(DBusConnection *connection);
		DBusMessage *dbus_message_new_method_call(const char *destination, const char *path,
			const char *interface, const char *method);
		DBusMessage *dbus_connection_send_with_reply_and_block(DBusConnection *connection,
			DBusMessage *message, int timeout, ImselectDBusError *error);
		unsigned int dbus_message_get_args(DBusMessage *message, ImselectDBusError *error,
			int first_type, ...);
		void dbus_message_unref(DBusMessage *message);
	]])
	dbus = ffi.load("libdbus-1.so.3")
	return M
end)

local function fail(err, context)
	local message = err.message ~= nil and ffi.string(err.message) or "out of memory"
	dbus.dbus_error_free(err)
	error("imselect: D-Bus " .. context .. ": " .. message)
end

local function close(bus)
	dbus.dbus_connection_close(bus)
	dbus.dbus_connection_unref(bus)
end

local function call(method)
	local err = ffi.new("ImselectDBusError")
	dbus.dbus_error_init(err)
	if connection and dbus.dbus_connection_get_is_connected(connection) == 0 then
		close(ffi.gc(connection, nil))
		connection = nil
	end
	if not connection then
		local bus = dbus.dbus_bus_get_private(0, err) -- DBUS_BUS_SESSION
		if bus == nil then
			return fail(err, "connect")
		end
		dbus.dbus_connection_set_exit_on_disconnect(bus, 0)
		connection = ffi.gc(bus, close)
	end
	local request =
		dbus.dbus_message_new_method_call("org.fcitx.Fcitx5", "/controller", "org.fcitx.Fcitx.Controller1", method)
	if request == nil then
		return fail(err, method)
	end
	local reply = dbus.dbus_connection_send_with_reply_and_block(connection, request, 1000, err)
	dbus.dbus_message_unref(request)
	if reply == nil then
		return fail(err, method)
	end
	local state
	if method == "State" then
		local value = ffi.new("int32_t[1]")
		-- D-Bus INT32 ('i'); varargs require an explicitly typed terminating INVALID (0).
		local ok = dbus.dbus_message_get_args(reply, err, 105, value, ffi.new("int", 0))
		dbus.dbus_message_unref(reply)
		if ok == 0 then
			return fail(err, method)
		end
		state = value[0] == 2
	else
		dbus.dbus_message_unref(reply)
	end
	return state
end

function M.get_state()
	return call("State")
end

function M.set_state(state)
	call(state and "Activate" or "Deactivate")
end

return M
