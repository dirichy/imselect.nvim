---@meta
---@alias Imselect.State boolean|string
---@class Imselect.Driver
---@field ascii_state? Imselect.State State used for ASCII input by the restore helper.
local M = {}
--- temporarily enter ASCII input mode
function M.temp_ascii() end
--- restore input method state before temp_ascii()
function M.restore() end

--- Alternative to temp_ascii/restore: query and set the driver's opaque state.
---@param callback? fun(state: Imselect.State?, err:string?) Optional asynchronous query.
---@return Imselect.State
---@overload fun(callback:fun(state:Imselect.State?,err:string?)):vim.SystemObj
function M.get_state(callback) end

---@param state Imselect.State
function M.set_state(state) end

--- setup driver
---@param opts table
---@return Imselect.Driver
function M.setup(opts) end
return M
