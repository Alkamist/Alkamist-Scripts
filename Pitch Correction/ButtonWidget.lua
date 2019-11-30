local pairs = pairs

local ButtonWidget = {}

function ButtonWidget.new(Button, Widget)
    local self = {}
    for k, v in pairs(Widget) do self[k] = v end
    for k, v in pairs(Button) do self[k] = v end

    function self:draw()
        local w, h = self.width, self.height

        -- Draw the body.
        self:setColor(self.color)
        self:drawRectangle(1, 1, w - 2, h - 2, true)

        -- Draw a dark outline around.
        self:setColor(self.outlineColor)
        self:drawRectangle(0, 0, w, h, false)

        -- Draw a light outline around.
        self:setColor(self.highlightColor)
        self:drawRectangle(1, 1, w - 2, h - 2, false)

        if self.isPressed then
            self:setColor(self.pressColor)
            self:drawRectangle(1, 1, w - 2, h - 2, true)
        end
    end

    return self
end

return ButtonWidget