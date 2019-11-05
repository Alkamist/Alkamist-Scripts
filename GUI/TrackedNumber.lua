local function TrackedNumber(initialValue)
    local self = {}

    local _current = initialValue or 0
    local _previous = initialValue or 0

    function self.justChanged()
        return _current ~= _previous
    end
    function self.getChange()
        return _current - _previous
    end
    function self.getValue()
        return _current
    end
    function self.getPreviousValue()
        return _previous
    end

    function self.setValue(value)
        _current = value
    end
    function self.update(value)
        _previous = _current
        if value ~= nil then _current = value end
    end

    return self
end

return TrackedNumber