---@meta
---@class Imselect.Inspecter
---@field priority number
local M = {}
--- setup inspecter
---@param opts table
function M.setup(opts) end

--- Try to apply inspecter on buffer
---@param buffer number
---@return boolean Return true if success, false if not success.
function M.apply(buffer) end
