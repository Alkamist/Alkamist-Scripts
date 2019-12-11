local GUI = require("GUI")
local setColor = GUI.setColor
local drawLine = GUI.drawLine
local drawCircle = GUI.drawCircle

local PitchCorrectionDraw = {}

function PitchCorrectionDraw:requires()
    return self.PitchCorrectionDraw
end
function PitchCorrectionDraw:getDefaults()
    local defaults = {}
    defaults.point = {}
    defaults.nextPoint = {}
    defaults.glowIndex = nil
    defaults.activeColor = { 0.3, 0.3, 0.8, 1, 0 }
    defaults.inactiveColor = { 0.8, 0.3, 0.3, 1, 0 }
    defaults.glowColor = { 1, 1, 1, 0.4, 1 }
    return defaults
end
function PitchCorrectionDraw:update(dt)
    local point = self.point
    local pointX = point.x
    local pointY = point.y
    local pointIsActive = point.isActive
    local nextPoint = self.nextPoint
    local glowIndex = self.glowIndex
    local activeColor = self.activeColor
    local inactiveColor = self.inactiveColor
    local glowColor = self.glowColor

    if nextPoint and pointIsActive then
        local nextPointX = nextPoint.x
        local nextPointY = nextPoint.y

        setColor(activeColor)
        drawLine(pointX, pointY, nextPointX, nextPointY, true)

        if glowIndex == 2 then
            setColor(glowColor)
            drawLine(pointX, pointY, nextPointX, nextPointY, true)
        end
    end

    if pointIsActive then
        setColor(activeColor)
    else
        setColor(inactiveColor)
    end
    drawCircle(pointX, pointY, 5, true, true)

    if glowIndex == 1 then
        setColor(glowColor)
        drawCircle(pointX, pointY, 5, true, true)
    end
end

return PitchCorrectionDraw