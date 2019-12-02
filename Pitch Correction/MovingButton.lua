local MovingButton = {}

function MovingButton:new()
    local self = self or {}
    for k, v in pairs(MovingButton) do if self[k] == nil then self[k] = v end end

    self._hasDraggedSincePress = false

    return self
end

function MovingButton:getX() end
function MovingButton:getPreviousX() end
function MovingButton:getY() end
function MovingButton:getPreviousY() end

function MovingButton:justMoved()
    local x1, x2, y1, y2 = self:getX(), self:getPreviousX(), self:getY(), self:getPreviousY()
    return x1 ~= x2 or y1 ~= y2
end
function MovingButton:justDragged() return self:isPressed() and self:justMoved() end
function MovingButton:hasDraggedSincePress() return self._hasDraggedSincePress end
function MovingButton:justStartedDragging() return self:justDragged() and not self:hasDraggedSincePress() end
function MovingButton:justStoppedDragging() return self:justReleased() and not  self:hasDraggedSincePress() end

function MovingButton:update()
    if self:justDragged() then self._hasDraggedSincePress = true end
    if self:justReleased() then self._hasDraggedSincePress = false end
end

return MovingButton