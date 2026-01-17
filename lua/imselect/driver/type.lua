---@meta
---@class Imselect.Driver
local M = {}
--- active im
--- @return boolean
function M.active() end
--- disable im
--- @return boolean
function M.disable() end
--- judge if im active
--- @return boolean
function M.is_active() end

--- setup driver
---@param opts table
---@return Imselect.Driver
function M.setup(opts) end
return M
