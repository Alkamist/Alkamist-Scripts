local Button = {}

-- isPressed, wasPreviouslyPressed
function Button:updateButton()
    self.justPressed = self.isPressed and not self.wasPreviouslyPressed
    self.justReleased = not self.isPressed and self.wasPreviouslyPressed
end

-- isPressed, wasPreviouslyPressed, x, y, previousX, previousY
function Button:updateMovingButton()
    Button.updateButton(self)
    self.justMoved = self.x ~= self.previousX or self.y ~= self.previousY
    self.justDragged = self.isPressed and self.justMoved
    self.justStartedDragging = self.justDragged and not self.hasDraggedSincePress
    self.justStoppedDragging = self.justReleased and self.hasDraggedSincePress
    if self.justDragged then self.hasDraggedSincePress = true end
    if self.justReleased then self.hasDraggedSincePress = false end
end

-- drawable, isPressed, width, height, bodyColor, outlineColor, highlightColor, pressedColor
function Button:drawButton()
    local w, h = self.width, self.height

    -- Draw the body.
    drawable:setColor(self.bodyColor)
    drawable:drawRectangle(1, 1, w - 2, h - 2, true)

    -- Draw a dark outline around.
    drawable:setColor(self.outlineColor)
    drawable:drawRectangle(0, 0, w, h, false)

    -- Draw a light outline around.
    drawable:setColor(self.highlightColor)
    drawable:drawRectangle(1, 1, w - 2, h - 2, false)

    if self.isPressed then
        drawable:setColor(self.pressedColor)
        drawable:drawRectangle(1, 1, w - 2, h - 2, true)
    end
end

return Button