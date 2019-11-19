local Toggle = {}

function Toggle:new(parameters)
    local parameters = parameters or {}
    local self = parameters.fromObject or {}

    local _currentState = parameters.state
    local _previousState = parameters.previousState

    function self:getState() return _currentState end
    function self:setState(value) _currentState = value end
    function self:toggle() _currentState = not _currentState end
    function self:getPreviousState() return _previousState end
    function self:justTurnedOn() return _currentState and not _previousState end
    function self:justTurnedOff() return not _currentState and _previousState end
    function self:update(state)
        _previousState = _currentState
        if state ~= nil then _currentState = state end
    end

    return self
end

return Toggle