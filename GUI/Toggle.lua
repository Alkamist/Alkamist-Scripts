local Toggle = {}

function Toggle:new(state)
    local self = setmetatable({}, { __index = self })

    self:setState(state)
    self:setPreviousState(state)

    return self
end

function Toggle:getState() return self._state end
function Toggle:setState(value) self._state = value end
function Toggle:getPreviousState() return self._previousState end
function Toggle:setPreviousState(value) self._previousState = value end

function Toggle:toggle() self:setState(not self:getState()) end
function Toggle:justChanged() return self:getState() ~= self:getPreviousState() end
function Toggle:justTurnedOn() return self:getState() and not self:getPreviousState() end
function Toggle:justTurnedOff() return not self:getState() and self:getPreviousState() end
function Toggle:update(state)
    self:setPreviousState(self:getState())
    if state ~= nil then self:setState(state) end
end

return Toggle