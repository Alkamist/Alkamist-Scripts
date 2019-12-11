local GUI = require("GUI")
local setColor = GUI.setColor
local drawLine = GUI.drawLine
local drawRectangle = GUI.drawRectangle

local PitchLineDraw = {}

function PitchLineDraw:requires()
    return self.PitchLineDraw
end
function PitchLineDraw:getDefaults()
    local defaults = {}
    defaults.x = 0
    defaults.y = 0
    defaults.nextPoint = nil
    defaults.glowPoint = false
    defaults.glowLine = false
    defaults.uncorrectedColor = { 0.3, 0.4, 0.3, 1, 0 }
    defaults.correctedColor = { 0.3, 0.8, 0.3, 1, 0 }
    defaults.glowColor = { 1, 1, 1, 0.4, 1 }
    return defaults
end
function PitchLineDraw:update(dt)
    local pointX = self.x
    local pointY = self.y
    local pointCorrectedY = self.correctedY
    local nextPoint = self.nextPoint
    local uncorrectedColor = self.uncorrectedColor
    local correctedColor = self.correctedColor
    local glowColor = self.glowColor
    local glowPoint = self.glowPoint
    local glowLine = self.glowLine

    if nextPoint then
        local nextPointX = nextPoint.x
        local nextPointY = nextPoint.y
        local nextPointCorrectedY = nextPoint.correctedY

        setColor(uncorrectedColor)
        drawLine(pointX, pointY, nextPointX, nextPointY, true)

        if glowLine then
            setColor(glowColor)
            drawLine(pointX, pointY, nextPointX, nextPointY, true)
        end

        setColor(correctedColor)
        drawLine(pointX, pointCorrectedY, nextPointX, nextPointCorrectedY, true)

        if glowLine then
            setColor(glowColor)
            drawLine(pointX, pointCorrectedY, nextPointX, nextPointCorrectedY, true)
        end
    end

    setColor(correctedColor)
    drawRectangle(pointX - 1, pointCorrectedY - 1, 3, 3, true)

    if glowPoint then
        setColor(glowColor)
        drawRectangle(pointX - 1, pointCorrectedY - 1, 3, 3, true)
    end
end

return PitchLineDraw