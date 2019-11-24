local reaper = reaper
local pairs = pairs

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GUI = require("GUI.AlkamistGUI")
local mouse = GUI.mouse
local graphics = GUI.graphics

local Button = {}
function Button:new(object)
    local self = self

    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    self.mouseIsInside = false
    self.mouseWasPreviouslyInside = false
    self.mouseJustEntered = false
    self.mouseJustLeft = false

    self.isPressed = false
    self.wasPreviouslyPressed = false
    self.justPressed = false
    self.justReleased = false
    self.isGlowing = false
    self.glowWhenMouseIsOver = true
    self.pressControl = nil
    self.toggleControl = nil

    self.label = ""
    self.labelFont = "Arial"
    self.labelFontSize = 14
    self.labelColor = { 1.0, 1.0, 1.0, 0.4, 1 }
    self.color = { 0.3, 0.3, 0.3, 1.0, 0 }
    self.downColor = { 1.0, 1.0, 1.0, -0.15, 1 }
    self.outlineColor = { 0.15, 0.15, 0.15, 1.0, 0 }
    self.edgeColor = { 1.0, 1.0, 1.0, 0.1, 1 }
    self.glowColor = { 1.0, 1.0, 1.0, 0.15, 1 }

    local object = object or {}
    for k, v in pairs(self) do if not object[k] then object[k] = v end end
    return object
end

function Button:pointIsInside(pointX, pointY)
    local x, y, w, h = self.x, self.y, self.width, self.height
    return pointX >= x and pointX <= x + w
       and pointY >= y and pointY <= y + h
end
function Button:update()
    self.justPressed = self.isPressed and not self.wasPreviouslyPressed
    self.justReleased = not self.isPressed and self.wasPreviouslyPressed
    self.mouseIsInside = self:pointIsInside(mouse.x, mouse.y)
    self.mouseJustEntered = self.mouseIsInside and not self.mouseWasPreviouslyInside
    self.mouseJustLeft = not self.mouseIsInside and self.mouseWasPreviouslyInside

    if self.glowWhenMouseIsOver then
        if self.mouseJustEntered then self.isGlowing = true end
        if self.mouseJustLeft then self.isGlowing = false end
    end
    if self.pressControl then
        if self.pressControl.justPressed and self.mouseIsInside then self.isPressed = true end
        if self.pressControl.justReleased then self.isPressed = false end
    end
    if self.toggleControl then
        if self.toggleControl.justPressed and self.mouseIsInside then self.isPressed = not self.isPressed end
    end
end
function Button:draw()
    local x, y, w, h = self.x, self.y, self.width, self.height

    -- Draw the body.
    graphics:setColor(self.color)
    graphics:drawRectangle(x, y, w, h, true)

    -- Draw a dark outline around.
    graphics:setColor(self.outlineColor)
    graphics:drawRectangle(x, y, w, h, false)

    -- Draw a light outline around.
    graphics:setColor(self.edgeColor)
    graphics:drawRectangle(x + 1, y + 1, w - 2, h - 2, false)

    -- Draw the label.
    graphics:setColor(self.labelColor)
    graphics:setFont(self.labelFont, self.labelFontSize)
    graphics:drawString(self.label, x, y, 5, x + w, y + h)

    if self.isPressed then
        graphics:setColor(self.downColor)
        graphics:drawRectangle(x + 1, y + 1, w - 2, h - 2, true)

    elseif self.isGlowing then
        graphics:setColor(self.glowColor)
        graphics:drawRectangle(x + 1, y + 1, w - 2, h - 2, true)
    end
end
function Button:endUpdate()
    self.wasPreviouslyPressed = self.isPressed
    self.mouseWasPreviouslyInside = self.mouseIsInside
end

return Button