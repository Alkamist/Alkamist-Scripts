local GUI = require("GUI")
local mouse = GUI.mouse
local mouseButtons = mouse.buttons
local leftMouseButton = mouseButtons.left
local middleMouseButton = mouseButtons.middle
local rightMouseButton = mouseButtons.right
local keyboard = GUI.keyboard
local keyboardModifiers = keyboard.modifiers
local shiftKey = keyboardModifiers.shift
local controlKey = keyboardModifiers.control
local windowsKey = keyboardModifiers.windows
local altKey = keyboardModifiers.alt
local keyboardKeys = GUI.keyboard.keys
local window = GUI.window

local pairs = pairs
local type = type

local Fn = require("Fn")
local initialize = Fn.initialize

local function updateWidgetMouseControlState(widget, control)
    if control.justPressed and widget.mouseIsInside then
        widget._controlWasPressedInside[control] = true
    end
    if control.justReleased then
        widget._controlWasPressedInside[control] = false
    end
end

local Widget = {}
function Widget:new()
    local defaults = {
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        mouseIsInside = false,
        _controlWasPressedInside = {}
    }

    initialize(self, defaults)
    initialize(self, Widget)
    return self
end

function Widget:controlWasPressedInside(control)
    return self._controlWasPressedInside[control]
end
function Widget:controlJustDragged(control)
    return self._controlWasPressedInside[control] and control.justDragged
end
function Widget:controlJustStartedDragging(control)
    return self._controlWasPressedInside[control] and control.justStartedDragging
end
function Widget:controlJustStoppedDragging(control)
    return self._controlWasPressedInside[control] and control.justStoppedDragging
end
function Widget:pointIsInside(point)
    local x, y, w, h = self.x, self.y, self.width, self.height
    local pointX, pointY = point.x, point.y
    return pointX >= x and pointX <= x + w
       and pointY >= y and pointY <= y + h
end
local mousePoint = {}
function Widget:update()
    mousePoint.x, mousePoint.y = mouse.x, mouse.y
    self.mouseIsInside = self:pointIsInside(mousePoint)

    for k, v in pairs(mouseButtons) do updateWidgetMouseControlState(self, v) end
    for k, v in pairs(keyboardModifiers) do updateWidgetMouseControlState(self, v) end
    for k, v in pairs(keyboardKeys) do updateWidgetMouseControlState(self, v) end
end
function Widget:draw() end
function Widget:endUpdate() end

return Widget