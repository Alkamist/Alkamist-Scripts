local MouseButtons = require("MouseButtons")
local ControlledButton = require("ControlledButton")
local DrawableButton = require("DrawableButton")

local WidgetButton = {}

function WidgetButton:new(object)
    local object = object or {}
    local defaults = {
        pressControl = MouseButtons.left,
        toggleControl = MouseButtons.right,
    }

    for k, v in pairs(defaults) do if object[k] == nil then object[k] = v end end
    for k, v in pairs(self) do if object[k] == nil then object[k] = v end end
    return DrawableButton:new(ControlledButton:new(object))
end

return WidgetButton