local reaper = reaper
local pairs = pairs

local Fn = require("Fn")
local GUI = require("GUI")
local mouse = GUI.mouse
local mouseButtons = mouse.buttons
local keyboard = GUI.keyboard
local keyboardModifiers = keyboard.modifiers
local keyboardKeys = GUI.keyboard.keys

local function updateWidgetMouseControl(widget, control)
    if widget.mouseIsInside and control.justPressed then
        widget.controlWasPressedInside[control] = true
    end
    if control.justReleased then
        widget.controlWasPressedInside[control] = false
    end
end

local Widget = {}
function Widget.new(object)
    local self = {}

    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    self.mouseIsInside = false
    self.mouseWasPreviouslyInside = false
    self.mouseJustEntered = false
    self.mouseJustLeft = false
    self.controlWasPressedInside = {}

    return Fn.makeNew(self, Widget, object)
end

function Widget:justDraggedBy(control)
    return control.justDragged and self.controlWasPressedInside[control]
end
function Widget:justStartedDraggingBy(control)
    return control.justStartedDragging and self.controlWasPressedInside[control]
end
function Widget:justStoppedDraggingBy(control)
    return control.justStoppedDragging and self.controlWasPressedInside[control]
end
function Widget:pointIsInside(pointX, pointY)
    local x, y, w, h = self.x, self.y, self.width, self.height
    return pointX >= x and pointX <= x + w
       and pointY >= y and pointY <= y + h
end
function Widget:update()
    self.mouseIsInside = self:pointIsInside(mouse.x, mouse.y)
    self.mouseJustEntered = self.mouseIsInside and not self.mouseWasPreviouslyInside
    self.mouseJustLeft = not self.mouseIsInside and self.mouseWasPreviouslyInside

    for _, button in pairs(mouseButtons) do
        updateWidgetMouseControl(self, button)
    end
    for _, modifier in pairs(keyboardModifiers) do
        updateWidgetMouseControl(self, modifier)
    end
    for _, key in pairs(keyboardKeys) do
        updateWidgetMouseControl(self, key)
    end
end
function Widget:endUpdate()
    self.mouseWasPreviouslyInside = self.mouseIsInside
end

return Widget