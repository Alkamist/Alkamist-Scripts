local TrackedNumber = {}

function TrackedNumber:new(number)
    local self = setmetatable({}, { __index = self })

    self.previous = number
    self.current = number
    self.change = 0
    self.justChanged = false

    return self
end

function TrackedNumber:update(number)
    self.previous = self.current
    if number then self.current = number end
    self.change = self.current - self.previous
    self.justChanged = self.change ~= 0
end
function TrackedNumber:set(number)
    self.current = number
end

return TrackedNumber