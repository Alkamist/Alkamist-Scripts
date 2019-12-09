local Position = require("Position")

local Button = {}

function Button:new()
    local self = self or {}
    Position.new(self)
    for k, v in pairs(Button) do self[k] = v end
    self:setIsPressed(false)
    self:setWasPreviouslyPressed(false)
    self:setHasDraggedSincePress(false)
    return self
end

function Button:isPressed() return self._isPressed end
function Button:setIsPressed(v) self._isPressed = v end
function Button:wasPreviouslyPressed() return self._wasPreviouslyPressed end
function Button:setWasPreviouslyPressed(v) self._wasPreviouslyPressed = v end
function Button:hasDraggedSincePress() return self._hasDraggedSincePress end
function Button:setHasDraggedSincePress(v) self._hasDraggedSincePress = v end

function Button:justPressed() return self:isPressed() and not self:wasPreviouslyPressed() end
function Button:justReleased() return not self:isPressed() and self:wasPreviouslyPressed() end
function Button:justDragged() return self:isPressed() and self:justMoved() end
function Button:justStartedDragging() return self:justDragged() and not self:hasDraggedSincePress() end
function Button:justStoppedDragging() return self:justReleased() and self:hasDraggedSincePress() end

function Button:update(dt)
    Position.update(self, dt)
    if self:justDragged() then self:setHasDraggedSincePress(true) end
    if self:justReleased() then self:setHasDraggedSincePress(false) end
    self:setWasPreviouslyPressed(self:isPressed())
end

return Button