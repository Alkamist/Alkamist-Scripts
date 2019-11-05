local function Toggle(initialState)
    local self = {}

    if initialState == nil then initialState = false end
    local _current = initialState
    local _previous = initialState

    function self.justTurnedOn()
        return _current and not _previous
    end
    function self.justTurnedOff()
        return not _current and _previous
    end
    function self.getState()
        return _current
    end
    function self.getPreviousState()
        return _previous
    end

    function self.toggle()
        _current = not _current
    end
    function self.setState(state)
        _current = state
    end
    function self.update(state)
        _previous = _current
        if state ~= nil then _current = state end
    end

    return self
end

return Toggle