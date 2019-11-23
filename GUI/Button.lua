local reaper = reaper
local pairs = pairs

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GUI = require("GUI.AlkamistGUI")

local Button = {}
function Button.new(object)
    local object = object or {}
    local button = {}

    button.x = 0
    button.y = 0
    button.width = 0
    button.height = 0
    button.label = ""
    button.labelFont = "Arial"
    button.labelFontSize = 14
    button.labelColor = { 1.0, 1.0, 1.0, 0.4, 1 }
    button.color = { 0.3, 0.3, 0.3, 1.0, 0 }
    button.downColor = { 1.0, 1.0, 1.0, -0.15, 1 }
    button.outlineColor = { 0.15, 0.15, 0.15, 1.0, 0 }
    button.edgeColor = { 1.0, 1.0, 1.0, 0.1, 1 }
    button.glowColor = { 1.0, 1.0, 1.0, 0.15, 1 }
    button.downState = false
    button.previousDownState = false
    button.glowState = false

    for k, v in pairs(button) do if not object[k] then object[k] = v end end
    return object
end

function Button:press()
    self.downState = true
end
function Button:release()
    self.downState = false
end
function Button:toggle()
    self.downState = not self.downState
end
function Button:glow()
    self.glowState = true
end
function Button:unGlow()
    self.glowState = false
end
function Button:toggleGlow()
    self.glowState = not self.glowState
end
function Button:updateStates()
    self.previousDownState = self.downState
end
function Button:draw()
    local x, y, w, h = self.x, self.y, self.width, self.height

    -- Draw the body.
    GUI.setColor(self.color)
    GUI.drawRectangle(x, y, w, h, true)

    -- Draw a dark outline around.
    GUI.setColor(self.outlineColor)
    GUI.drawRectangle(x, y, w, h, false)

    -- Draw a light outline around.
    GUI.setColor(self.edgeColor)
    GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, false)

    -- Draw the label.
    GUI.setColor(self.labelColor)
    GUI.setFont(self.labelFont, self.labelFontSize)
    GUI.drawString(self.label, x, y, 5, x + w, y + h)

    if self.downState then
        GUI.setColor(self.downColor)
        GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, true)

    elseif self.glowState then
        GUI.setColor(self.glowColor)
        GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, true)
    end
end

return Button