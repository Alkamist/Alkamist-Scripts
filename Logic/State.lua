local State = {}

function State:new(initialValue)
    local self = setmetatable({}, { __index  = self })

    local initialValue = initialValue or false

    self.current  = initialValue
    self.previous = initialValue
    self.changed  = false

    return self
end

function State:update(state)
    self.previous = self.current
    self.current = state
    self.changed = self.current ~= self.previous
end

return State