package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Prototype = require("Prototype")

return Prototype:new{
    currentValue = 0,
    previousValue = 0,
    justChanged = { get = function(self) return self.currentValue ~= self.previousValue end },
    change = { get = function(self) return self.currentValue - self.previousValue end },
    update = function(self, value)
        self.previousValue = self.currentValue
        if value ~= nil then self.currentValue = value end
    end
}
