local ToggleState = {}

function ToggleState:new(state)
    local self = setmetatable({}, { __index = self })

    if state ~= nil then self.previous = state else self.previous = false end
    if state ~= nil then self.current = state else self.current = false end
    self.justTurnedOn = false
    self.justTurnedOff = false

    return self
end

function ToggleState:update(state)
    self.previous = self.current
    if state ~= nil then self.current = state end
    self.justTurnedOn = self.current and not self.previous
    self.justTurnedOff = not self.current and self.previous
end
function ToggleState:set(state)
    self.current = state
end
function ToggleState:toggle()
    self.current = not self.current
end

return ToggleState