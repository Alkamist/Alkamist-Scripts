local Graphics = require("Graphics")
local MovingButton = require("MovingButton")

local DrawableButton = MovingButton:new()

function DrawableButton:initialize()
    MovingButton.initialize(self)

    local defaults = {
        width = 0,
        height = 0,
        bodyColor = { 0.4, 0.4, 0.4, 1, 0 },
        outlineColor = { 0.15, 0.15, 0.15, 1, 0 },
        highlightColor = { 1, 1, 1, 0.15, 1 },
        pressedColor = { 1, 1, 1, -0.15, 1 },
        graphics = Graphics:new()
    }

    for k, v in pairs(defaults) do
        if self[k] == nil then
            self[k] = v
        end
    end
end

function DrawableButton:pointIsInside(point)
    return point.x >= self.x and point.y <= self.x + self.width
       and point.y >= self.y and point.y <= self.y + self.height
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