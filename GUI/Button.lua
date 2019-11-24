local reaper = reaper
local pairs = pairs

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GUI = require("GUI.AlkamistGUI")

local Button = {}
function Button:new(object)
    local self = {}

    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    self.label = ""
    self.labelFont = "Arial"
    self.labelFontSize = 14
    self.labelColor = { 1.0, 1.0, 1.0, 0.4, 1 }
    self.color = { 0.3, 0.3, 0.3, 1.0, 0 }
    self.downColor = { 1.0, 1.0, 1.0, -0.15, 1 }
    self.outlineColor = { 0.15, 0.15, 0.15, 1.0, 0 }
    self.edgeColor = { 1.0, 1.0, 1.0, 0.1, 1 }
    self.glowColor = { 1.0, 1.0, 1.0, 0.15, 1 }
    self.downState = false
    self.previousDownState = false
    self.glowState = false

    local object = object or {}
    for k, v in pairs(self) do if not object[k] then object[k] = v end end
    return object
end

function Button:pointIsInside(pointX, pointY)
    local x, y, w, h = self.x, self.y, self.width, self.height
    return pointX >= x and pointX <= x + w
       and pointY >= y and pointY <= y + h
end
function Button:mouseIsInside()
    return pointIsInsideBox(GUI:getMouseX(), GUI:getMouseY())
end
function Button:isPressed() return self.downState end
function Button:justPressed() return self.downState and not self.previousDownState end
function Button:justReleased() return not self.downState and self.previousDownState end
function Button:press() self.downState = true end
function Button:release() self.downState = false end
function Button:toggle() self.downState = not self.downState end
function Button:glow() self.glowState = true end
function Button:unGlow() self.glowState = false end
function Button:toggleGlow() self.glowState = not self.glowState end
function Button:updateStates() self.previousDownState = self.downState end
function Button:handleGlowOnMouseOver()
    if self:mouseIsInside() then
        self.glowState = true
    end
end
function Button:draw()
    local x, y, w, h = self.x, self.y, self.width, self.height

    -- Draw the body.
    GUI:setColor(self.color)
    GUI:drawRectangle(x, y, w, h, true)

    -- Draw a dark outline around.
    GUI:setColor(self.outlineColor)
    GUI:drawRectangle(x, y, w, h, false)

    -- Draw a light outline around.
    GUI:setColor(self.edgeColor)
    GUI:drawRectangle(x + 1, y + 1, w - 2, h - 2, false)

    -- Draw the label.
    GUI:setColor(self.labelColor)
    GUI:setFont(self.labelFont, self.labelFontSize)
    GUI:drawString(self.label, x, y, 5, x + w, y + h)

    if self.downState then
        GUI:setColor(self.downColor)
        GUI:drawRectangle(x + 1, y + 1, w - 2, h - 2, true)

    elseif self.glowState then
        GUI:setColor(self.glowColor)
        GUI:drawRectangle(x + 1, y + 1, w - 2, h - 2, true)
    end
end

return Button