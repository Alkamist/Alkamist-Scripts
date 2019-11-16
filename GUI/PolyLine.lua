local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Prototype = require("Prototype")
local Widget = require("GUI.Widget")

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
local function insertThingIntoGroup(group, newThing, stoppingConditionFn)
    local numberInGroup = #group
    if numberInGroup == 0 then
        group[1] = newThing
        return 1
    end

    for i = 1, numberInGroup do
        local thing = group[i]
        if stoppingConditionFn(thing, newThing) then
            table.insert(group, i, newThing)
            return i
        end
    end

    group[numberInGroup + 1] = newThing
    return numberInGroup + 1
end

return Prototype:new{
    calledWhenCreated = function(self) end,

    prototypes = {
        { "widget", Widget }
    },

    points = {},
    mostRecentInsertedIndex = true,
    isVertical = false,
    pointSize = 3,
    segmentColor = { 0.5, 0.5, 0.5, 1, 0 },
    segmentGlowColor = { 0.8, 0.8, 0.8, 1, 0 },
    pointColor = { 0.56, 0.56, 0.56, 1, 0 },
    pointGlowColor = { 0.85, 0.85, 0.85, 1, 0 },
    glowWhenMouseOverSegment = false,
    glowWhenMouseOverPoint = false,
    glowIndex = nil,

    insertPoint = function(self, point)
        local newIndex
        if self.isVertical then
            newIndex = insertThingIntoGroup(self.points, point, function(pointInLoop, pointToInsert)
                return pointInLoop.y >= pointToInsert.y
            end)
        else
            newIndex = insertThingIntoGroup(self.points, point, function(pointInLoop, pointToInsert)
                return pointInLoop.x >= pointToInsert.x
            end)
        end
        mostRecentInsertedIndex = newIndex
    end,
    sortPoints = function(self)
        if self.isVertical then
            table.sort(self.points, function(left, right)
                return left.y < right.y
            end)
        else
            table.sort(self.points, function(left, right)
                return left.x < right.x
            end)
        end
    end,
    getIndexAndDistanceOfSegmentClosestToPoint = function(self, x, y)
        local points = self.points
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
    end,
    getIndexAndDistanceOfPointClosestToPoint = function(self, x, y)
        local points = self.points
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
    end,
    getIndexOfPointOrSegmentClosestToPointWithinDistance = function(self, x, y, distance)
        local index
        local indexIsPoint
        local segmentIndex, segmentDistance = self:getIndexAndDistanceOfSegmentClosestToPoint(x, y)
        local pointIndex, pointDistance = self:getIndexAndDistanceOfPointClosestToPoint(x, y)
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
    end,

    --update = function(self)
    --    local mouse = self.GUI.mouse
    --end,
    drawSegment = function(self, index, color)
        local points = self.points
        local point = points[index]
        local nextPoint = points[index + 1]
        if point == nil then return end
        if nextPoint == nil then return end

        self:setColor(color)
        self:drawLine(point.x, point.y, nextPoint.x, nextPoint.y, true)
    end,
    drawPoint = function(self, index, color, size, asSquare)
        local points = self.points
        local point = points[index]
        if point == nil then return end

        self:setColor(color)
        if asSquare then
            self:drawRectangle(point.x - 1, point.y - 1, size, size, true)
        else
            self:drawCircle(point.x, point.y, size, true, true)
        end
    end,
    draw = function(self)
        local width = self.width
        local height = self.height
        local points = self.points

        for i = 1, #points do
            if glowWhenMouseOverSegment and glowIndex == i then
                self:drawSegment(i, self.segmentGlowColor)
            else
                self:drawSegment(i, self.segmentColor)
            end

            if glowWhenMouseOverPoint and glowIndex == i then
                self:drawPoint(i, self.pointGlowColor, self.pointSize, true)
            else
                self:drawPoint(i, self.pointColor, self.pointSize, true)
            end
        end
    end
}