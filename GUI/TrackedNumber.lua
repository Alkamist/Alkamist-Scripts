package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Prototype = require("Prototype")

local TrackedNumber = {
    currentValue = false,
    previousValue = false
}

function TrackedNumber:get() return self.currentValue end
function TrackedNumber:set(value) self.currentValue = value end

function TrackedNumber:justChanged() return self.currentValue ~= self.previousValue end
function TrackedNumber:getChange() return self.currentValue - self.previousValue end

function TrackedNumber:update(value)
    self.previousValue = self.currentValue
    if value ~= nil then self.currentValue = value end
end

return Prototype:new(TrackedNumber)