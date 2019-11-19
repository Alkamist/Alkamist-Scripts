local TrackedNumber = {}

function TrackedNumber:new(parameters)
    local parameters = parameters or {}
    local self = parameters.fromObject or {}

    local _currentValue = parameters.value or 0
    local _previousValue = parameters.previousValue or 0

    function self:getValue() return _currentValue end
    function self:setValue(value) _currentValue = value end
    function self:getPreviousValue() return _previousValue end
    function self:getChange() return _currentValue - _previousValue end
    function self:justChanged() return _currentValue ~= _previousValue end
    function self:update(value)
        _previousValue = _currentValue
        if value ~= nil then _currentValue = value end
    end

    return self
end

return TrackedNumber
