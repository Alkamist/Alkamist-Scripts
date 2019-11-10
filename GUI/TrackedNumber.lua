package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Proxy = require("Proxy")

local TrackedNumber = {
    currentValue = 0,
    previousValue = 0,
    justChanged = { get = function(self) return self.currentValue ~= self.previousValue end },
    change = { get = function(self) return self.currentValue - self.previousValue end }
}

function TrackedNumber:update(value)
    self.previousValue = self.currentValue
    if value ~= nil then self.currentValue = value end
end

return Proxy:createPrototype(TrackedNumber)