package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Prototype = require("Prototype")

local Toggle = {
    currentState = false,
    previousState = false
}

function Toggle:justTurnedOn() return self.currentState and not self.previousState end
function Toggle:justTurnedOff() return not self.currentState and self.previousState end

function Toggle:toggle() _current = not _current end
function Toggle:update(state)
    self.previousState = self.currentState
    if state ~= nil then self.currentState = state end
end

return Prototype:new(Toggle)