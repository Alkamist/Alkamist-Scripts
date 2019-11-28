local reaper = reaper
local pairs = pairs

local Proxy = require("Proxy")
local Fn = require("Fn")
--local GUI = require("GUI")
--local mouse = GUI.mouse
--local mouseButtons = mouse.buttons
--local keyboard = GUI.keyboard
--local keyboardModifiers = keyboard.modifiers
--local keyboardKeys = GUI.keyboard.keys

local Widget = {}
function Widget:new()
    local defaults = {
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        alpha = 1.0,
        blendMode = 0,
        widgets = {}
    }

    Proxy.new(self)

    Fn.initialize(self, defaults)
    Fn.initialize(self, Widget)
    return self
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
            childWidget:doUpdate()
        end
    end
end
function Widget:doUpdate()
    self:doChildWidgetUpdates()
    if self.update then self:update() end
end
function Widget:doChildWidgetDraws()
    local childWidgets = self.widgets
    if childWidgets then
        for i = 1, #childWidgets do
            local childWidget = childWidgets[i]
            childWidget:doDraw()
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
            childWidget:doEndUpdate()
        end
    end
end
function Widget:doEndUpdate()
    self:doChildWidgetEndUpdates()
    if self.endUpdate then self:endUpdate() end
end

return Widget