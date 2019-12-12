local GUI = require("GUI")

local math = math
local sqrt = math.sqrt
local table = table
local tableInsert = table.insert

local function getMinimumDistanceBetweenPointAndLineSegment(pointX, pointY, lineX1, lineY1, lineX2, lineY2)
    local A = pointX - lineX1
    local B = pointY - lineY1
    local C = lineX2 - lineX1
    local D = lineY2 - lineY1
    local dotProduct = A * C + B * D
    local lengthSquared = C * C + D * D
    local param = -1
    local xx
    local yy

    if lengthSquared ~= 0 then
        param = dotProduct / lengthSquared
    end

    if param < 0 then
        xx = lineX1
        yy = lineY1
    elseif param > 1 then
        xx = lineX2
        yy = lineY2
    else
        xx = lineX1 + param * C
        yy = lineY1 + param * D
    end

    local dx = pointX - xx
    local dy = pointY - yy

    return sqrt(dx * dx + dy * dy)
end
local function getDistanceBetweenTwoPoints(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return sqrt(dx * dx + dy * dy)
end

local PolyLineState = {}

function PolyLineState:requires()
    return self.PolyLineState
end
function PolyLineState:getDefaults()
    local defaults = {}
    defaults.points = {}
    defaults.mouseEditPixelRange = 6
    defaults.glowWhenMouseIsOver = true
    defaults.mouseOverIndex = nil
    defaults.mouseOverDistance = nil
    defaults.mouseIsOverPoint = nil
    return defaults
end
function PolyLineState:update()
    local points = self.points
    local mouseX = GUI.mouseX
    local mouseY = GUI.mouseY

    local lowestPointDistance
    local closestPointIndex = 1
    local lowestLineDistance
    local closestLineIndex = 1

    for i = 1, #points do
        local point = points[i]
        local pointX = point.x
        local pointY = point.y

        local pointDistance = getDistanceBetweenTwoPoints(mouseX, mouseY, pointX, pointY)

        lowestPointDistance = lowestPointDistance or pointDistance
        if pointDistance < lowestPointDistance then
            lowestPointDistance = pointDistance
            closestPointIndex = i
        end

        local nextPoint = points[i + 1]
        if nextPoint then
            local nextPointX = nextPoint.x
            local nextPointY = nextPoint.y

            local lineDistance = getMinimumDistanceBetweenPointAndLineSegment(mouseX, mouseY, pointX, pointY, nextPointX, nextPointY)
            lowestLineDistance = lowestLineDistance or lineDistance
            if lineDistance < lowestLineDistance then
                lowestLineDistance = lineDistance
                closestLineIndex = i
            end
        end
    end

    local mouseOverIndex
    local mouseOverDistance
    local mouseIsOverPoint
    local mouseEditPixelRange = self.mouseEditPixelRange

    if lowestPointDistance < mouseEditPixelRange then
        mouseOverIndex = closestPointIndex
        mouseOverDistance = lowestPointDistance
        mouseIsOverPoint = true

    elseif lowestLineDistance < mouseEditPixelRange then
        mouseOverIndex = closestLineIndex
        mouseOverDistance = lowestLineDistance
        mouseIsOverPoint = false
    end

    self.mouseOverIndex = mouseOverIndex
    self.mouseOverDistance = mouseOverDistance
    self.mouseIsOverPoint = mouseIsOverPoint
end

return PolyLineState