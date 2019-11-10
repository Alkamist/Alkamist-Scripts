package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Proxy = require("Proxy")

local Toggle = {
    currentState = false,
    previousState = false,
    justTurnedOn = { get = function(self) return self.currentState and not self.previousState end },
    justTurnedOff = { get = function(self) return not self.currentState and self.previousState end }
}

function Toggle:toggle() self.currentState = not self.currentState end
function Toggle:update(state)
    self.previousState = self.currentState
    if state ~= nil then self.currentState = state end
end

return Proxy:createPrototype(Toggle)