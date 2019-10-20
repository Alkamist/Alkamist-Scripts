package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local State = require("Logic.State")

local Switch = setmetatable({}, { __index  = State })
local Switch_mt = {
    __index  = Switch,
    __add    = function(left, right) return Operators.onTable(left, right, Operators.add) end,
    __sub    = function(left, right) return Operators.onTable(left, right, Operators.sub) end,
    __mul    = function(left, right) return Operators.onTable(left, right, Operators.mul) end,
    __div    = function(left, right) return Operators.onTable(left, right, Operators.div) end,
    __idiv   = function(left, right) return Operators.onTable(left, right, Operators.idiv) end,
    __mod    = function(left, right) return Operators.onTable(left, right, Operators.mod) end,
    __pow    = function(left, right) return Operators.onTable(left, right, Operators.pow) end,
    __concat = function(left, right) return Operators.onTable(left, right, Operators.concat) end,
    __band   = function(left, right) return Operators.onTable(left, right, Operators.band) end,
    __bor    = function(left, right) return Operators.onTable(left, right, Operators.bor) end,
    __bxor   = function(left, right) return Operators.onTable(left, right, Operators.bxor) end,
    __bnot   = function(left, right) return Operators.onTable(left, right, Operators.bnot) end,
    __shl    = function(left, right) return Operators.onTable(left, right, Operators.shl) end,
    __shr    = function(left, right) return Operators.onTable(left, right, Operators.shr) end,
    __eq     = function(left, right) return Operators.onTable(left, right, Operators.eq) end,
    __lt     = function(left, right) return Operators.onTable(left, right, Operators.lt) end,
    __le     = function(left, right) return Operators.onTable(left, right, Operators.le) end
}

function Switch:new(initialValue)
    local base = State:new(initialValue)
    local self = setmetatable(base, Switch_mt)

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