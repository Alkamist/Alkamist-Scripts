local reaper = reaper
local gfx = gfx
local pairs = pairs
local math = math
local table = table

local BoxSelect = require("BoxSelect")
local GUI = require("GUI")
local mouse = GUI.mouse
local keyboard = GUI.keyboard
local leftMouseButton = mouse.buttons.left
local rightMouseButton = mouse.buttons.right
local shiftKey = keyboard.modifiers.shift
local controlKey = keyboard.modifiers.control
local graphics = GUI.graphics

local function arrayRemove(t, fn)
    local n = #t
    local j = 1
    for i = 1, n do
        if not fn(i, j) then
            if i ~= j then
                t[j] = t[i]
                t[i] = nil
            end
            j = j + 1
        else
            t[i] = nil
        end
    end
    return t
end
local function minimumDistanceBetweenPointAndLineSegment(pointX, pointY, lineX1, lineY1, lineX2, lineY2)
    if pointX == nil or pointY == nil or lineX1 == nil or lineY1 == nil or lineX2 == nil or lineY2 == nil then
        return 0.0
    end
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

    return math.sqrt(dx * dx + dy * dy)
end
local function distanceBetweenTwoPoints(x1, y1, x2, y2)
    if x1 == nil or y1 == nil or x2 == nil or y2 == nil then
        return 0.0
    end
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end
local function getIndexAndDistanceOfSegmentClosestToPoint(points, x, y)
    local numberOfPoints = #points
    if numberOfPoints < 1 then return nil end

    local lowestDistance
    local lowestDistanceIndex = 1

    for i = 1, numberOfPoints do
        local point = points[i]
        local nextPoint = points[i + 1]

        local distance
        if nextPoint then
            distance = minimumDistanceBetweenPointAndLineSegment(x, y, point.x, point.y, nextPoint.x, nextPoint.y)
        end
        lowestDistance = lowestDistance or distance

        if distance and distance < lowestDistance then
            lowestDistance = distance
            lowestDistanceIndex = i
        end
    end

    return lowestDistanceIndex, lowestDistance
end
local function getIndexAndDistanceOfPointClosestToPoint(points, x, y)
    local numberOfPoints = #points
    if numberOfPoints < 1 then return nil end

    local lowestDistance
    local lowestDistanceIndex = 1

    for i = 1, numberOfPoints do
        local point = points[i]

        local distance = distanceBetweenTwoPoints(x, y, point.x, point.y)
        lowestDistance = lowestDistance or distance

        if distance and distance < lowestDistance then
            lowestDistance = distance
            lowestDistanceIndex = i
        end
    end

    return lowestDistanceIndex, lowestDistance
end
local function getIndexOfPointOrSegmentClosestToPointWithinDistance(points, x, y, distance)
    local index
    local indexIsPoint
    local segmentIndex, segmentDistance = getIndexAndDistanceOfSegmentClosestToPoint(points, x, y)
    local pointIndex, pointDistance = getIndexAndDistanceOfPointClosestToPoint(points, x, y)
    local pointIsClose = false
    local segmentIsClose = false

    if pointDistance then pointIsClose = pointDistance <= distance end
    if segmentDistance then segmentIsClose = segmentDistance <= distance end

    if pointIsClose or segmentIsClose then
        if segmentIsClose then
            index = segmentIndex
            indexIsPoint = false
        end
        if pointIsClose then
            index = pointIndex
            indexIsPoint = true
        end
    end
    return index, indexIsPoint
end
local function insertThingIntoGroup(group, newThing, sortFn)
    local numberInGroup = #group
    if numberInGroup == 0 then
        group[1] = newThing
        return 1
    end

    for i = 1, numberInGroup do
        local thing = group[i]
        if not sortFn(thing, newThing) then
            table.insert(group, i, newThing)
            return i
        end
    end

    group[numberInGroup + 1] = newThing
    return numberInGroup + 1
end
local function moveSelectedPointsWithMouse(points)
    local mouseXChange = mouse.xChange
    local mouseYChange = mouse.yChange
    for i = 1, #points do
        local point = points[i]
        if point.isSelected then
            point.x = point.x + mouseXChange
            point.y = point.y + mouseYChange
        end
    end
end
local function unselectAllPoints(points)
    for i = 1, #points do
        local point = points[i]
        point.isSelected = false
    end
end
local function getPolyLineMouseOverStates(points, mousePixelEditRange, xOffset, yOffset)
    local mouseOverIndex, mouseIsOverPoint = getIndexOfPointOrSegmentClosestToPointWithinDistance(points, mouse.x + xOffset, mouse.y + yOffset, mousePixelEditRange)
    return mouseOverIndex, mouseIsOverPoint
end
local function updatePolyLine(points, mouseOverIndex, mouseIsOverPoint)
    local editPointIndex = nil
    local editPoint = nil
    if leftMouseButton.justPressed and mouseOverIndex then
        editPointIndex = mouseOverIndex
        editPoint = points[editPointIndex]

        if not editPoint.isSelected and not shiftKey.isPressed then
            unselectAllPoints(points)
        end

        editPoint.isSelected = true
        if not mouseIsOverPoint then
            points[editPointIndex + 1].isSelected = true
        end
    end

    if editPointIndex and mouse.justMoved then
        moveSelectedPointsWithMouse(points)
    end
end
local function drawPolyLine(points, drawLine, drawPoint, lineColor, pointColor, glowColor, mouseOverIndex, mouseIsOverPoint)
    local setColor = graphics.setColor

    for i = 1, #points do
        local point = points[i]
        local nextPoint = points[i + 1]
        local pointIsSelected = point.isSelected
        local shouldGlowLine = pointIsSelected or (mouseOverIndex == i and not mouseIsOverPoint)
        local shouldGlowPoint = pointIsSelected or (mouseOverIndex == i and mouseIsOverPoint)

        if nextPoint then
            setColor(lineColor)
            drawLine(point, nextPoint)

            if shouldGlowLine then
                setColor(glowColor)
                drawLine(point, nextPoint)
            end
        end

        setColor(pointColor)
        drawPoint(point)

        if shouldGlowPoint then
            setColor(glowColor)
            drawPoint(point)
        end
    end
end

local PolyLine = {}
function PolyLine.new(object)
    local self = {}

    self.x = 0
    self.y = 0
    self.points = {}
    self.editPointIndex = nil

    local lineColor = { 0.5, 0.5, 0.5, 1.0, 0 }
    self.lineColor = lineColor
    self.pointColor = { lineColor[1] + 0.03, lineColor[2] + 0.03, lineColor[3] + 0.03, lineColor[4], lineColor[5] }
    self.glowColor = { 1.0, 1.0, 1.0, 0.3, 1 }

    self.mouseEditPixelRange = 6
    self.glowWhenMouseIsOver = true

    self.drawLine = function(point, nextPoint) graphics.drawLine(point.x, point.y, nextPoint.x, nextPoint.y, true) end
    self.drawPoint = function(point) graphics.drawRectangle(point.x - 1, point.y - 1, 3, 3, true) end
    self.sortFunction = function(before, after) return before.x < after.x end

    self.boxSelect = BoxSelect.new{
        thingsToSelect = self.points,
        selectionControl = rightMouseButton,
        additiveControl = shiftKey,
        inversionControl = controlKey
    }

    local object = object or {}
    for k, v in pairs(self) do if object[k] == nil then object[k] = v end end
    return object
end
function PolyLine.update(self)
    BoxSelect.update(self.boxSelect)

    self.mouseOverIndex, self.mouseIsOverPoint = getIndexOfPointOrSegmentClosestToPointWithinDistance(self.points, mouse.x - self.x, mouse.y - self.y, self.mouseEditPixelRange)

    local editPoint = nil
    if leftMouseButton.justPressed and self.mouseOverIndex then
        self.editPointIndex = self.mouseOverIndex
        editPoint = self.points[self.editPointIndex]

        if not editPoint.isSelected and not self.boxSelect.additiveControl.isPressed then
            unselectAllPoints(self.points)
        end

        editPoint.isSelected = true
        if not self.mouseIsOverPoint then
            self.points[self.editPointIndex + 1].isSelected = true
        end
    end

    if self.editPointIndex and mouse.justMoved then
        movePointsWithMouse(points, function(point) return point.isSelected end)
    end

    if leftMouseButton.justReleased then
        self.editPointIndex = nil
    end
end
function PolyLine.draw(self)
    local setColor = graphics.setColor
    local drawLine = self.drawLine
    local drawPoint = self.drawPoint
    local lineColor = self.lineColor
    local pointColor = self.pointColor
    local glowColor = self.glowColor
    local mouseOverIndex = self.mouseOverIndex
    local mouseIsOverPoint = self.mouseIsOverPoint
    local glowWhenMouseIsOver = self.glowWhenMouseIsOver
    local points = self.points

    for i = 1, #points do
        local point = points[i]
        local nextPoint = points[i + 1]
        local pointIsSelected = point.isSelected
        local shouldGlowLine = pointIsSelected or (glowWhenMouseIsOver and mouseOverIndex == i and not mouseIsOverPoint)
        local shouldGlowPoint = pointIsSelected or (glowWhenMouseIsOver and mouseOverIndex == i and mouseIsOverPoint)

        if nextPoint then
            setColor(lineColor)
            drawLine(point, nextPoint)

            if shouldGlowLine then
                setColor(glowColor)
                drawLine(point, nextPoint)
            end
        end

        setColor(pointColor)
        drawPoint(point)

        if shouldGlowPoint then
            setColor(glowColor)
            drawPoint(point)
        end
    end

    BoxSelect.draw(self.boxSelect)
end

return PolyLine