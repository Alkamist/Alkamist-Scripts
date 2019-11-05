local function Toggle(initialState)
    local instance = {}

    if initialState == nil then initialState = false end
    local _current = initialState
    local _previous = initialState

    function instance:justTurnedOn()
        return _current and not _previous
    end
    function instance:justTurnedOff()
        return not _current and _previous
    end
    function instance:getState()
        return _current
    end
    function instance:getPreviousState()
        return _previous
    end

    function instance:toggle()
        _current = not _current
    end
    function instance:setState(state)
        _current = state
    end
    function instance:update(state)
        _previous = _current
        if state ~= nil then _current = state end
    end

    return instance
end

return Toggle