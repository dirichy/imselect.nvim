---@meta
---@alias Imselect.Inspecter fun(buffer:number):boolean
---@class Imselect.Strategy
---@field priority number will try every strategy from high priority to low priority
---@field name string the name of the strategy, used in opts.
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

--- Classify the cursor context in Insert mode only: true restores input, false requests ASCII.
--- Mode requirements are applied by the caller and cannot be overridden here.
--- note that this function will be called rapidly, so don't make it too heavy.
---@param buffer number
---@return boolean
---@type Imselect.Inspecter
function M.inspecter(buffer) end
