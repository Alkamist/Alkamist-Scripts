local pairs = pairs

local DrawableButton = {}

function DrawableButton.new(button, drawable, bounds, colors)
    local self = {}
    for k, v in pairs(button) do self[k] = v end

    self.colors = colors
    self.bounds = bounds
    self.drawable = drawable

    function self:draw()
        local w, h = self.width, self.height
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

        if self.isPressed then
            drawable:setColor(colors.pressed)
            drawable:drawRectangle(1, 1, w - 2, h - 2, true)
        end
    end

    return self
end

return DrawableButton