---@meta
---@class Imselect.Driver
local M = {}
--- active im
--- @return boolean
function M.active() end
--- disable im
--- @return boolean
function M.disable() end

---judge if im is active
---@param callback nil if set, will run async and call callback with the result
---@return boolean
---@overload fun(callback:fun(obj:boolean)):vim.SystemObj
function M.is_active(callback) end

--- setup driver
---@param opts table
---@return Imselect.Driver
function M.setup(opts) end
return M
