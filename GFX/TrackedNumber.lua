local TrackedNumber = {}

function TrackedNumber:new(number)
    local self = setmetatable({}, { __index = self })

    self.previous = number
    self.current = number

    return self
end

function TrackedNumber:update(number)
    self.previous = self.current
    if number then self.current = number end
end
function TrackedNumber:set(number)
    self.current = number
end
function TrackedNumber:justChanged()
    return self.current ~= self.previous
end
function TrackedNumber:getChange()
    return self.current - self.previous
end

return TrackedNumber