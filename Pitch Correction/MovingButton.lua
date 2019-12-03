-- x, y, previousX, previousY
local MovingButton = {}

function MovingButton:update()
    self.justMoved = self.x ~= self.previousX or self.y ~= self.previousY
    self.justDragged = self.isPressed and self.justMoved
    if self.justDragged then self.hasDraggedSincePress = true end
    if self.justReleased then self.hasDraggedSincePress = false end
    self.justStartedDragging = self.justDragged and not self.hasDraggedSincePress
    self.justStoppedDragging = self.justReleased and not self.hasDraggedSincePress
end

return MovingButton