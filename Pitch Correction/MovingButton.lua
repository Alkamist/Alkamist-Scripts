-- x, y
return function(self, state)
    local _previousX = state.x
    local _previousY = state.y
    local _hasDraggedSincePress = false

    function self.hasDraggedSincePress() return _hasDraggedSincePress end
    function self.justMoved() return state.x ~= _previousX or state.y ~= _previousY end
    function self.justDragged() return self.isPressed() and self.justMoved() end
    function self.justStartedDragging() return self.justDragged() and not _hasDraggedSincePress end
    function self.justStoppedDragging() return self.justReleased() and not  _hasDraggedSincePress end

    local _oldUpdate = self.update
    function self.update()
        _oldUpdate()
        _previousX = _x
        _previousY = _y
        if self.justDragged() then _hasDraggedSincePress = true end
        if self.justReleased() then _hasDraggedSincePress = false end
    end

    return self
end