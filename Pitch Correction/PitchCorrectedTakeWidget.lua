local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Proxy = require("Proxy")
local Widget = require("GUI.Widget")
local Take = require("Pitch Correction.Take")
local PitchCorrectedTake = require("Pitch Correction.PitchCorrectedTake")

local PitchCorrectedTakeWidget = {}
function PitchCorrectedTakeWidget:new(parameters)
    local self = PitchCorrectedTake:new(Widget:new())

    self.shouldDrawDirectly = true
    self.pitchLineColor = { 0.26, 0.66, 0.26, 1.0, 0 }
    self.pitchPointColor = { 0.3, 0.7, 0.3, 1.0, 0 }

    function self:draw()
        local points = self.pitchAnalyzer.points
        local drawRectangle = self.drawRectangle
        local drawLine = self.drawLine
        local setColor = self.setColor
        local pointColor = self.pitchPointColor
        local lineColor = self.pitchLineColor
        for i = 1, #points do
            local point = points[i]
            local nextPoint = points[i + 1]
            if nextPoint and math.abs(nextPoint.time - point.time) < 0.1 then
                setColor(self, lineColor)
                drawLine(self, point.x, point.y, nextPoint.x, nextPoint.y, true)
            end
            setColor(self, pointColor)
            drawRectangle(self, point.x - 1, point.y - 1, 3, 3, true)
        end
    end

    for k, v in pairs(parameters or {}) do self[k] = v end
    return self
end

return PitchCorrectedTakeWidget