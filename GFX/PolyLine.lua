local function minimumDistanceBetweenPointAndLineSegment(pointX, pointY, lineX1, lineY1, lineX2, lineY2)
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



local PolyLine = {}

function PolyLine:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.parent = init.parent
    self.points = {}

    if init.isHorizontal ~= nil then self.isHorizontal = init.isHorizontal else self.isHorizontal = true end

    self.color = init.color or { 0.7, 0.7, 0.7, 1.0, 0 }

    return self
end

function PolyLine:insertPoint(point)
    local newIndex

    if self.isHorizontal then
        newIndex = insertThingIntoGroup(self.points, point, function(pointInLoop, pointToInsert)
            return pointInLoop.x >= pointToInsert.x
        end)
    else
        newIndex = insertThingIntoGroup(self.points, point, function(pointInLoop, pointToInsert)
            return pointInLoop.y >= pointToInsert.y
        end)
    end

    return newIndex
end
function PolyLine:sortPoints()
    if self.isHorizontal then
        table.sort(self.points, function(left, right)
            return left.x < right.x
        end)
    else
        table.sort(self.points, function(left, right)
            return left.y < right.y
        end)
    end
end
function PolyLine:applyFunctionToAllPoints(fn)
    local numberOfPoints = #self.points
    for i = 1, numberOfPoints do
        local point = self.points[i]
        fn(point)
    end
end
function PolyLine:applyFunctionToSpecificPoints(specificIndexes, fn)
    local numberOfPoints = #self.specificIndexes
    for i = 1, numberOfPoints do
        local pointIndex = self.specificIndexes[i]
        local point = self.points[pointIndex]
        fn(point)
    end
end
function PolyLine:moveAllPoints(xChange, yChange)
    self:applyFunctionToAllPoints(function(point)
        point.x = point.x + xChange
        point.y = point.y + yChange
    end)
    self:sortPoints()
end
function PolyLine:moveAllPointsWithMouse()
    self:moveAllPoints(self.parent.GFX.mouseXChange, self.parent.GFX.mouseYChange)
end
function PolyLine:moveSpecificPoints(indexesToMove, xChange, yChange)
    self:applyFunctionToSpecificPoints(indexesToMove, function(point)
        point.x = point.x + xChange
        point.y = point.y + yChange
    end)
    self:sortPoints()
end
function PolyLine:moveSpecificPointsWithMouse(indexesToMove)
    self:moveSpecificPoints(indexesToMove, self.parent.GFX.mouseXChange, self.parent.GFX.mouseYChange)
end
function PolyLine:getIndexAndDistanceOfSegmentClosestToPoint(x, y)
    local numberOfPoints = #self.points
    if numberOfPoints < 1 then return nil end

    local lowestDistance
    local lowestDistanceIndex = 1

    for i = 1, numberOfPoints do
        local point =     self.points[i]
        local nextPoint = self.points[i + 1]

        local lineDistance
        if nextPoint then
            lineDistance = minimumDistanceBetweenPointAndLineSegment(x, y, point.x, point.y, nextPoint.x, nextPoint.y)
        end
        lowestDistance = lowestDistance or lineDistance

        if lineDistance and lineDistance < lowestDistance then
            lowestDistance = lineDistance
            lowestDistanceIndex = i
        end
    end

    return lowestDistanceIndex, lowestDistance
end
function PolyLine:draw()
    local numberOfPoints = #self.points
    for i = 1, numberOfPoints do
        local point =     self.points[i]
        local nextPoint = self.points[i + 1]

        self.parent:setColor(self.color)

        if nextPoint then
            self.parent:drawLine(point.x, point.y, nextPoint.x, nextPoint.y, true)
        end
    end
end

return PolyLine