local pairs = pairs

-- width, height, bodyColor, outlineColor, highlightColor, pressedColor
return function(self, state)
    function self.draw()
        local w, h = state.width, state.height

        -- Draw the body.
        self.setColor(state.bodyColor)
        self.drawRectangle(1, 1, w - 2, h - 2, true)

        -- Draw a dark outline around.
        self.setColor(state.outlineColor)
        self.drawRectangle(0, 0, w, h, false)

        -- Draw a light outline around.
        self.setColor(state.highlightColor)
        self.drawRectangle(1, 1, w - 2, h - 2, false)

        if self.isPressed() then
            self.setColor(state.pressedColor)
            self.drawRectangle(1, 1, w - 2, h - 2, true)
        end
    end

    return self
end