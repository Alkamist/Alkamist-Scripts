-- isPressed
return function(self, state)
    local _wasPreviouslyPressed = state.isPressed

    function self.isPressed() return state.isPressed end
    function self.justPressed() return state.isPressed and not _wasPreviouslyPressed end
    function self.justReleased() return not state.isPressed and _wasPreviouslyPressed end

    function self.update()
        _wasPreviouslyPressed = state.isPressed
    end

    return self
end