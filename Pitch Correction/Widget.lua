local reaper = reaper
local pairs = pairs

local Fn = require("Fn")
local GUI = require("GUI")
local mouse = GUI.mouse
local mouseButtons = mouse.buttons
local keyboard = GUI.keyboard
local keyboardModifiers = keyboard.modifiers
local keyboardKeys = GUI.keyboard.keys

local Widget = {}
function Widget.new(self)
    local states = {}

    states.x = 0
    states.y = 0
    states.width = 0
    states.height = 0
    states.alpha = 1.0
    states.blendMode = 0
    states.mouseIsInside = false
    states.mouseWasPreviouslyInside = false
    states.mouseJustEntered = false
    states.mouseJustLeft = false
    states.controlWasPressedInside = {}
    states.pointIsInsideFn = function(self, pointX, pointY)
        local x, y, w, h = self.x, self.y, self.width, self.height
        return pointX >= x and pointX <= x + w
           and pointY >= y and pointY <= y + h
    end

    return Fn.initialize(self, states)
end

function Widget.justDraggedBy(self, control)
    return control.justDragged and self.controlWasPressedInside[control]
end
function Widget.justStartedDraggingBy(self, control)
    return control.justStartedDragging and self.controlWasPressedInside[control]
end
function Widget.justStoppedDraggingBy(self, control)
    return control.justStoppedDragging and self.controlWasPressedInside[control]
end
function Widget.update(self, updateFn)
    self.mouseIsInside = self:pointIsInsideFn(mouse.x, mouse.y)
    self.mouseJustEntered = self.mouseIsInside and not self.mouseWasPreviouslyInside
    self.mouseJustLeft = not self.mouseIsInside and self.mouseWasPreviouslyInside

    local function updateWidgetMouseControl(control)
        if self.mouseIsInside and control.justPressed then
            self.controlWasPressedInside[control] = true
        end
        if control.justReleased then
            self.controlWasPressedInside[control] = false
        end
    end

    for _, button in pairs(mouseButtons) do
        updateWidgetMouseControl(button)
    end
    for _, modifier in pairs(keyboardModifiers) do
        updateWidgetMouseControl(modifier)
    end
    for _, key in pairs(keyboardKeys) do
        updateWidgetMouseControl(key)
    end

    if updateFn then updateFn() end
end
function Widget.draw(self, drawFn)
    local a, mode, dest = gfx.a, gfx.mode, gfx.dest
    gfx.a = self.alpha
    gfx.mode = self.blendMode
    if drawFn then drawFn() end
    gfx.a, gfx.mode, gfx.dest = a, mode, dest
end
function Widget.endUpdate(self, endUpdateFn)
    self.mouseWasPreviouslyInside = self.mouseIsInside
    if endUpdateFn then endUpdateFn() end
end

return Widget