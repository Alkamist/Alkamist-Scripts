local GUI = require("GUI")
local setColor = GUI.setColor
local drawRectangle = GUI.drawRectangle

local table = table

local Button = {}

function Button:new()
    local self = self or {}

    local defaults = {}
    defaults.x = 0
    defaults.y = 0
    defaults.width = 0
    defaults.height = 0
    defaults.isPressed = false
    defaults.bodyColor = { 0.4, 0.4, 0.4, 1, 0 }
    defaults.outlineColor = { 0.15, 0.15, 0.15, 1, 0 }
    defaults.pressedColor = { 1, 1, 1, -0.1, 1 }
    defaults.highlightColor = { 1, 1, 1, 0.1, 1 }

    function defaults:pointIsInside(pointX, pointY)
        local x, y, w, h = self.x, self.y, self.width, self.height
        return pointX >= x and pointX <= x + w
           and pointY >= y and pointY <= y + h
    end

    for k, v in pairs(defaults) do if self[k] == nil then self[k] = v end end
    table.insert(GUI.leftMouseButton.trackedObjects, self)
    return self
end
function Button:update(dt)
    self.isPressed = GUI.leftMouseButton.wasPressedInsideObject[self]
    self.isGlowing = self:pointIsInside(GUI.mouseX, GUI.mouseY)
end
function Button:draw(dt)
    local x, y, w, h = self.x, self.y, self.width, self.height
    local bodyColor, outlineColor, highlightColor, pressedColor = self.bodyColor, self.outlineColor, self.highlightColor, self.pressedColor

    -- Draw the body.
    setColor(bodyColor)
    drawRectangle(x + 1, y + 1, w - 2, h - 2, true)

    -- Draw a dark outline around.
    setColor(outlineColor)
    drawRectangle(x, y, w, h, false)

    -- Draw a light outline around.
    setColor(highlightColor)
    drawRectangle(x + 1, y + 1, w - 2, h - 2, false)

    if self.isPressed then
        setColor(pressedColor)
        drawRectangle(x + 1, y + 1, w - 2, h - 2, true)

    elseif self.isGlowing then
        setColor(highlightColor)
        drawRectangle(x + 1, y + 1, w - 2, h - 2, true)
    end
end

return Button