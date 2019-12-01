local MovingButton = {}

function MovingButton.new(input)
    local self = {}
    for k, v in pairs(MovingButton) do if self[k] == nil then self[k] = v end end
    for k, v in pairs(input.button) do if self[k] == nil then self[k] = v end end

    self.x = input.x
    self.y = input.y

    self._hasDraggedSincePress = false

    return self
end

function MovingButton:justMoved()
    local x, y = self.x, self.y
    return x[1] ~= x[2] or y[1] ~= y[2]
end
function MovingButton:justDragged() return self:isPressed() and self:justMoved() end
function MovingButton:justStartedDragging() return self:justDragged() and not self._hasDraggedSincePress end
function MovingButton:justStoppedDragging() return self:justReleased() and not self._hasDraggedSincePress end
function MovingButton:update()
    if self:justDragged() then self._hasDraggedSincePress = true end
    if self:justReleased() then self._hasDraggedSincePress = false end
end