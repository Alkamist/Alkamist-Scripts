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
local function distanceBetweenTwoPoints(x1, y1, x2, y2)
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



local PolyLine = {}

function PolyLine:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.points = {}
    self.mostRecentInsertedIndex = nil

    if init.isHorizontal ~= nil then self.isHorizontal = init.isHorizontal else self.isHorizontal = true end

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
    self.mostRecentInsertedIndex = newIndex
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
function PolyLine:getIndexAndDistanceOfSegmentClosestToPoint(x, y)
    local numberOfPoints = #self.points
    if numberOfPoints < 1 then return nil end

    local lowestDistance
    local lowestDistanceIndex = 1

    for i = 1, numberOfPoints do
        local point =     self.points[i]
        local nextPoint = self.points[i + 1]

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
function PolyLine:getIndexAndDistanceOfPointClosestToPoint(x, y)
    local numberOfPoints = #self.points
    if numberOfPoints < 1 then return nil end

    local lowestDistance
    local lowestDistanceIndex = 1

    for i = 1, numberOfPoints do
        local point =     self.points[i]

        local distance = distanceBetweenTwoPoints(x, y, point.x, point.y)
        lowestDistance = lowestDistance or distance

        if distance and distance < lowestDistance then
            lowestDistance = distance
            lowestDistanceIndex = i
        end
    end

    return lowestDistanceIndex, lowestDistance
end

return PolyLine