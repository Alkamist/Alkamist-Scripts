local function TrackedNumber(initialValue)
    local instance = {}

    local _current = initialValue or 0
    local _previous = initialValue or 0

    function instance:justChanged()
        return _current ~= _previous
    end
    function instance:getChange()
        return _current - _previous
    end
    function instance:getValue()
        return _current
    end
    function instance:getPreviousValue()
        return _previous
    end

    function instance:setValue(value)
        _current = value
    end
    function instance:update(value)
        _previous = _current
        if value ~= nil then _current = value end
    end

    return instance
end

return TrackedNumber