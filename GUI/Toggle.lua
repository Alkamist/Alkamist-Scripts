package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Proxy = require("Proxy")

local Toggle = {}

function Toggle:new(parameters)
    local parameters = parameters or {}
    local self = Proxy:new()

    self.currentState = false
    self.previousState = false
    self.justTurnedOn = { get = function(self) return self.currentState and not self.previousState end }
    self.justTurnedOff = { get = function(self) return not self.currentState and self.previousState end }

    function self:update(state)
        self.previousState = self.currentState
        if state ~= nil then self.currentState = state end
    end

    for k, v in pairs(parameters) do self[k] = v end
    return self
end

return Toggle