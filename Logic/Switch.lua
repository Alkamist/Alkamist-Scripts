package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local State = require("Logic.State")

local Switch = setmetatable({}, { __index  = State })

function Switch:new(initialValue)
    local base = State:new(initialValue)
    local self = setmetatable(base, { __index  = self })

    self.activated =   false
    self.deactivated = false

    return self
end

function Switch:update(state)
    State.update(self, state)
    self.activated   = self.current and not self.previous
    self.deactivated = not self.current and self.previous
end

return Switch