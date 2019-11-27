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
function Widget:new()
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
    states.widgets = {}

    return Fn.initialize(self, Widget, states)
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
function Widget:doChildWidgetUpdates()
    local childWidgets = self.widgets
    if childWidgets then
        for i = 1, #childWidgets do
            local childWidget = childWidgets[i]
            childWidget.x = childWidget.x + self.x
            childWidget.y = childWidget.y + self.y
            childWidget:doUpdate()
            childWidget.x = childWidget.x - self.x
            childWidget.y = childWidget.y - self.y
        end
    end
end
function Widget:doUpdate()
    self:doChildWidgetUpdates()

    self.mouseIsInside = self:pointIsInside(mouse.x, mouse.y)
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

    if self.update then self:update() end
end
function Widget:doChildWidgetDraws()
    local childWidgets = self.widgets
    if childWidgets then
        for i = 1, #childWidgets do
            local childWidget = childWidgets[i]
            childWidget.x = childWidget.x + self.x
            childWidget.y = childWidget.y + self.y
            childWidget:doDraw()
            childWidget.x = childWidget.x - self.x
            childWidget.y = childWidget.y - self.y
        end
    end
end
function Widget:doDraw()
    local a, mode, dest = gfx.a, gfx.mode, gfx.dest
    gfx.a = self.alpha
    gfx.mode = self.blendMode
    if self.draw then self:draw() end
    gfx.a, gfx.mode, gfx.dest = a, mode, dest

    self:doChildWidgetDraws()
end
function Widget:doChildWidgetEndUpdates()
    local childWidgets = self.widgets
    if childWidgets then
        for i = 1, #childWidgets do
            local childWidget = childWidgets[i]
            childWidget.x = childWidget.x + self.x
            childWidget.y = childWidget.y + self.y
            childWidget:doEndUpdate()
            childWidget.x = childWidget.x - self.x
            childWidget.y = childWidget.y - self.y
        end
    end
end
function Widget:doEndUpdate()
    self:doChildWidgetEndUpdates()

    self.mouseWasPreviouslyInside = self.mouseIsInside
    if self.endUpdate then self:endUpdate() end
end

return Widget