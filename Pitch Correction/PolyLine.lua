local GUI = require("GUI")
local setColor = GUI.setColor

local BoxSelect = require("BoxSelect")

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
local function updateMouseOverInfo(self)
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

local PolyLine = {}

function PolyLine:new()
    local self = self or {}

    local defaults = {}
    defaults.x = 0
    defaults.y = 0
    defaults.width = 0
    defaults.height = 0
    defaults.mouseEditPixelRange = 6
    defaults.points = {}
    defaults.glowWhenMouseIsOver = true
    defaults.mouseOverIndex = nil
    defaults.mouseOverDistance = nil
    defaults.mouseIsOverPoint = nil
    defaults.lineColor = { 0.5, 0.5, 0.5, 1, 0 }
    defaults.pointShade = { 1, 1, 1, 0.1, 0 }
    defaults.glowColor = { 1.0, 1.0, 1.0, 0.4, 0 }
    defaults.drawLineFn = function(self, point, nextPoint) GUI.drawLine(point.x, point.y, nextPoint.x, nextPoint.y, true) end
    defaults.drawPointFn = function(self, point) GUI.drawRectangle(point.x - 1, point.y - 1, 3, 3, true) end

    function defaults:pointIsInside(pointX, pointY)
        local x, y, w, h = self.x, self.y, self.width, self.height
        return pointX >= x and pointX <= x + w
           and pointY >= y and pointY <= y + h
    end

    defaults.boxSelect = BoxSelect.new()

    for k, v in pairs(defaults) do if self[k] == nil then self[k] = v end end
    --tableInsert(GUI.leftMouseButton.trackedObjects, self)
    --tableInsert(GUI.rightMouseButton.trackedObjects, self)
    return self
end

function PolyLine:update(dt)
    self.boxSelect.objectsToSelect = self.points
    updateMouseOverInfo(self)
    BoxSelect.update(self.boxSelect, dt)
end
function PolyLine:draw(dt)
    local points = self.points
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

    BoxSelect.draw(self.boxSelect, dt)
end

return PolyLine