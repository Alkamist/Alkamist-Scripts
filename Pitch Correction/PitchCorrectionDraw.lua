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
    defaults.x = 0
    defaults.y = 0
    defaults.isActive = true
    defaults.nextPoint = nil
    defaults.glowPoint = false
    defaults.glowLine = false
    defaults.activeColor = { 0.3, 0.3, 0.8, 1, 0 }
    defaults.inactiveColor = { 0.8, 0.3, 0.3, 1, 0 }
    defaults.glowColor = { 1, 1, 1, 0.4, 1 }
    return defaults
end
function PitchCorrectionDraw:update(dt)
    local pointX = self.x
    local pointY = self.y
    local pointIsActive = self.isActive
    local nextPoint = self.nextPoint
    local activeColor = self.activeColor
    local inactiveColor = self.inactiveColor
    local glowColor = self.glowColor
    local glowPoint = self.glowPoint
    local glowLine = self.glowLine

    if nextPoint and pointIsActive then
        local nextPointX = nextPoint.x
        local nextPointY = nextPoint.y

        setColor(activeColor)
        drawLine(pointX, pointY, nextPointX, nextPointY, true)

        if glowLine then
            setColor(glowColor)
            drawLine(pointX, pointY, nextPointX, nextPointY, true)
        end
    end

    if pointIsActive then
        setColor(activeColor)
    else
        setColor(inactiveColor)
    end
    drawCircle(pointX, pointY, 3, true, true)

    if glowPoint then
        setColor(glowColor)
        drawCircle(pointX, pointY, 3, true, true)
    end
end

return PitchCorrectionDraw