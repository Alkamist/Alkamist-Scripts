local pairs = pairs

local DrawableButton = {}

function DrawableButton:new()
    local self = self or {}

    self.x = self.x
    self.y = self.y
    self.width = self.width
    self.height = self.height
    self.button = self.button
    self.drawable = self.drawable
    self.colors = self.colors

    for k, v in pairs(DrawableButton) do if self[k] == nil then self[k] = v end end
    return self
end

function DrawableButton:draw()
    local w, h = self.width[1], self.height[1]
    local drawable = self.drawable
    local colors = self.colors

    -- Draw the body.
    drawable:setColor(colors.body)
    drawable:drawRectangle(1, 1, w - 2, h - 2, true)

    -- Draw a dark outline around.
    drawable:setColor(colors.outline)
    drawable:drawRectangle(0, 0, w, h, false)

    -- Draw a light outline around.
    drawable:setColor(colors.highlight)
    drawable:drawRectangle(1, 1, w - 2, h - 2, false)

    if self.button:isPressed() then
        drawable:setColor(colors.pressed)
        drawable:drawRectangle(1, 1, w - 2, h - 2, true)
    end
end

return DrawableButton