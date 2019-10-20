package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Operators = require("Logic.Operators")
local State = require("Logic.State")

local NumberTracker = setmetatable({}, { __index = State })
local NumberTracker_mt = {
    __index  = NumberTracker,
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

function NumberTracker:new(initialValue)
    local base = State:new(initialValue)
    local self = setmetatable(base, NumberTracker_mt)

    self.delta = 0

    return self
end

function NumberTracker:update(value)
    State.update(self, value)
    self.delta = self.current - self.previous
end

return NumberTracker