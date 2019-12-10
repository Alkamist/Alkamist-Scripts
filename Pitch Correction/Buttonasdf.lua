local Position = require("Position")

return function(self)
    local self = self or {}
    if self.Button then return self end
    self.Button = true
    Position(self)
    local _positionUpdatePreviousState = self.updatePreviousState

    local _isPressed
    local _wasPreviouslyPressed
    local _hasDraggedSincePress

    function self.isPressed() return _isPressed end
    function self.setIsPressed(v) _isPressed = v end
    function self.wasPreviouslyPressed() return _wasPreviouslyPressed end
    function self.setWasPreviouslyPressed(v) _wasPreviouslyPressed = v end
    function self.hasDraggedSincePress() return _hasDraggedSincePress end
    function self.setHasDraggedSincePress(v) _hasDraggedSincePress = v end

    function self.justPressed() return self.isPressed() and not self.wasPreviouslyPressed() end
    function self.justReleased() return not self.isPressed() and self.wasPreviouslyPressed() end
    function self.justDragged() return self.isPressed() and self.justMoved() end
    function self.justStartedDragging() return self.justDragged() and not self.hasDraggedSincePress() end
    function self.justStoppedDragging() return self.justReleased() and self.hasDraggedSincePress() end

    function self.updatePreviousState(dt)
        if self.justDragged() then self.setHasDraggedSincePress(true) end
        if self.justReleased() then self.setHasDraggedSincePress(false) end
        self.setWasPreviouslyPressed(self.isPressed())
        _positionUpdatePreviousState(dt)
    end

    self.setIsPressed(false)
    self.setWasPreviouslyPressed(false)
    self.setHasDraggedSincePress(false)

    return self
end