package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Class = require("Class")

local TrackedNumber = {
    current = 0,
    previous = 0
}
function TrackedNumber:create(parameters)
    return Class.create({ TrackedNumber }, parameters)
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