local Graphics = require("Graphics")
local MovingButton = require("MovingButton")

local DrawableButton = {}

function DrawableButton:new(object)
    local object = object or {}
    local defaults = {
        width = 0,
        height = 0,
        bodyColor = { 0.4, 0.4, 0.4, 1, 0 },
        outlineColor = { 0.15, 0.15, 0.15, 1, 0 },
        highlightColor = { 1, 1, 1, 0.15, 1 },
        pressedColor = { 1, 1, 1, -0.15, 1 },
        graphics = Graphics:new{
            x = object.x,
            y = object.y
        }
    }

    for k, v in pairs(defaults) do if object[k] == nil then object[k] = v end end
    for k, v in pairs(self) do if object[k] == nil then object[k] = v end end
    return MovingButton:new(object)
end

function DrawableButton:draw()
    local graphics = self.graphics
    local w, h = self.width, self.height

    -- Draw the body.
    graphics:setColor(self.bodyColor)
    graphics:drawRectangle(1, 1, w - 2, h - 2, true)

    -- Draw a dark outline around.
    graphics:setColor(self.outlineColor)
    graphics:drawRectangle(0, 0, w, h, false)

    -- Draw a light outline around.
    graphics:setColor(self.highlightColor)
    graphics:drawRectangle(1, 1, w - 2, h - 2, false)

    if self.isPressed then
        graphics:setColor(self.pressedColor)
        graphics:drawRectangle(1, 1, w - 2, h - 2, true)
    end
end

return DrawableButton