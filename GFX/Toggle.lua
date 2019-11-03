package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Class = require("Class")

local Toggle = {
    current = false,
    previous = false
}
function Toggle:new(input)
    return Class:new({ Toggle }, input)
end

function Toggle:set(value)
    self.current = value
    return self
end
function Toggle:toggle()
    self.current = not self.current
    return self
end
function Toggle:update(value)
    self.previous = self.current
    if value ~= nil then self.current = value end
    return self
end
function Toggle:justTurnedOn()
    return self.current and not self.previous
end
function Toggle:justTurnedOff()
    return not self.current and self.previous
end

return Toggle