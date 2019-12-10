local GUI = require("GUI")
local Widget = require("Widget")

local Button = {}

function Button:new(object)
    local object = object or {}
    local defaults = {}
    defaults.x = 0
    defaults.y = 0
    defaults.width = 0
    defaults.height = 0
    defaults.isPressed = false
    defaults.isGlowing = false
    defaults.bodyColor = { 0.4, 0.4, 0.4, 1, 0 }
    defaults.outlineColor = { 0.15, 0.15, 0.15, 1, 0 }
    defaults.pressedColor = { 1, 1, 1, -0.1, 1 }
    defaults.highlightColor = { 1, 1, 1, 0.1, 1 }
    for k, v in pairs(self) do if object[k] == nil then object[k] = v end end
    for k, v in pairs(defaults) do if object[k] == nil then object[k] = v end end
    return Widget:new(object)
end

function Button:onLeftMouseButtonJustPressed()
    self.isPressed = true
end
function Button:onLeftMouseButtonJustReleased()
    self.isPressed = false
end
function Button:onUpdate(dt)
    self.isGlowing = self:pointIsInside(GUI.mouseX, GUI.mouseY)
end
function Button:onDraw(dt)
    local x, y, w, h = self.x, self.y, self.width, self.height
    local isPressed, isGlowing = self.isPressed, self.isGlowing
    local bodyColor, outlineColor, highlightColor, pressedColor = self.bodyColor, self.outlineColor, self.highlightColor, self.pressedColor

    -- Draw the body.
    GUI.setColor(bodyColor)
    GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, true)

    -- Draw a dark outline around.
    GUI.setColor(outlineColor)
    GUI.drawRectangle(x, y, w, h, false)

    -- Draw a light outline around.
    GUI.setColor(highlightColor)
    GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, false)

    if isPressed then
        GUI.setColor(pressedColor)
        GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, true)

    elseif isGlowing then
        GUI.setColor(highlightColor)
        GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, true)
    end
end

return Button