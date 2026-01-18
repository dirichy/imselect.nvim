---@meta
---@alias Imselect.Inspecter fun(buffer:number):boolean
---@class Imselect.Strategy
---@field priority number will try every strategy from high priority to low priority
---@field apply (fun(buffer:number):boolean)| nil this function should set a inspecter for a buffer, return true for success, false for failure. If this filed is nil, will simply set inspecter of strategy as inspecter for the buffer.
local M = {}
---@type (fun(opts:table):Imselect.Strategy)|nil
M.setup = nil

-- - Try to apply inspecter on buffer
-- -@param buffer number
-- -@return boolean Return true if success, false if not success.
M.apply = nil

--- judge if the inspecter should be used
---@param buffer number
---@return boolean
function M.condition(buffer) end

--- this function should be a inspecter, take buffer number as variable. return true means the im should be active, false means the im should be disabled.
--- note that this function will be called rapidly, so don't make it too heavy.
---@param buffer number
---@return boolean
---@type Imselect.Inspecter
function M.inspecter(buffer) end
