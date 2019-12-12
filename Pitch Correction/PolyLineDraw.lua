local GUI = require("GUI")
local setColor = GUI.setColor

local PolyLineDraw = {}

function PolyLineDraw:requires()
    return self.PolyLineDraw
end
function PolyLineDraw:getDefaults()
    local defaults = {}
    defaults.points = {}
    defaults.glowWhenMouseIsOver = true
    defaults.mouseOverIndex = nil
    defaults.mouseIsOverPoint = nil
    defaults.lineColor = { 0.5, 0.5, 0.5, 1, 0 }
    defaults.pointShade = { 1, 1, 1, 0.1, 0 }
    defaults.glowColor = { 1.0, 1.0, 1.0, 0.4, 0 }
    defaults.drawLineFn = function(self, point, nextPoint) GUI.drawLine(point.x, point.y, nextPoint.x, nextPoint.y, true) end
    defaults.drawPointFn = function(self, point) GUI.drawRectangle(point.x - 1, point.y - 1, 3, 3, true) end
    return defaults
end
function PolyLineDraw:update(dt)
    local points = self.points
    if points == nil then return end
    local drawLineFn = self.drawLineFn
    local drawPointFn = self.drawPointFn
    local lineColor = self.lineColor
    local pointShade = self.pointShade
    local glowColor = self.glowColor
    local mouseOverIndex = self.mouseOverIndex
    local mouseIsOverPoint = self.mouseIsOverPoint
    local glowWhenMouseIsOver = self.glowWhenMouseIsOver

    for i = 1, #points do
        local point = points[i]
        local nextPoint = points[i + 1]
        local pointIsSelected = point.isSelected
        local shouldGlowLine = pointIsSelected or (glowWhenMouseIsOver and mouseOverIndex == i and not mouseIsOverPoint)
        local shouldGlowPoint = pointIsSelected or (glowWhenMouseIsOver and mouseOverIndex == i and mouseIsOverPoint)

        if nextPoint then
            setColor(lineColor)
            drawLineFn(self, point, nextPoint)

            if shouldGlowLine then
                setColor(glowColor)
                drawLineFn(self, point, nextPoint)
            end
        end

        setColor(lineColor)
        drawPointFn(self, point)

        setColor(pointShade)
        drawPointFn(self, point)

        if shouldGlowPoint then
            setColor(glowColor)
            drawPointFn(self, point)
        end
    end
end

return PolyLineDraw