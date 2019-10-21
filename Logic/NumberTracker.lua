package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local State = require("Logic.State")

local NumberTracker = setmetatable({}, { __index = State })

function NumberTracker:new(initialValue)
    local initialValue = initialValue or 0
    local base = State:new(initialValue)
    local self = setmetatable(base, { __index  = self })

    self.delta = 0

    return self
end

function NumberTracker:update(value)
    State.update(self, value)
    self.delta = self.current - self.previous
end

return NumberTracker