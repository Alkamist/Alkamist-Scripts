package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Proxy = require("Proxy")
local Widget = require("GUI.Widget")
local Take = require("Pitch Correction.Take")
local PitchCorrectedTake = require("Pitch Correction.PitchCorrectedTake")

local PitchCorrectedTakeWidget = {}
function PitchCorrectedTakeWidget:new(initialValues)
    local self = Widget:new(PitchCorrectedTake:new(initialValues))

    self.take = Take:new(initialValues.takePointer)

    function self:draw()
        local points = self.pitchAnalyzer.points
        local drawRectangle = self.drawRectangle
        for i = 1, #points do
            local point = points[i]
            drawRectangle(self, point.x, point.y, 3, 3, true)
        end
    end

    return Proxy:new(self, initialValues)
end

return PitchCorrectedTakeWidget