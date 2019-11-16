package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Proxy = require("Proxy")

local TrackedNumber = {}

function TrackedNumber:new(initialValues)
    local self = {}

    self.currentValue = 0
    self.previousValue = 0
    self.justChanged = { get = function(self) return self.currentValue ~= self.previousValue end }
    self.change = { get = function(self) return self.currentValue - self.previousValue end }

    function self:update(value)
        self.previousValue = self.currentValue
        if value ~= nil then self.currentValue = value end
    end

    return Proxy:new(self, initialValues)
end

return TrackedNumber
