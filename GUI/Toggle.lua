package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Prototype = require("Prototype")

return Prototype:new{
    currentState = false,
    previousState = false,
    justTurnedOn = { get = function(self) return self.currentState and not self.previousState end },
    justTurnedOff = { get = function(self) return not self.currentState and self.previousState end },
    toggle = function(self) self.currentState = not self.currentState end,
    update = function(self, state)
        self.previousState = self.currentState
        if state ~= nil then self.currentState = state end
    end
}