local math = math

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

local function PolyLine(parameters)
    local instance = {}

    _points = {}
    _mostRecentInsertedIndex = nil
    _isVertical = parameters.isVertical
    if _isVertical == nil then _isVertical = true end

    function instance:insertPoint(point)
        local newIndex
        if _isVertical then
            newIndex = insertThingIntoGroup(_points, point, function(pointInLoop, pointToInsert)
                return pointInLoop.y >= pointToInsert.y
            end)
        else
            newIndex = insertThingIntoGroup(_points, point, function(pointInLoop, pointToInsert)
                return pointInLoop.x >= pointToInsert.x
            end)
        end
        _mostRecentInsertedIndex = newIndex
    end
    function instance:sortPoints()
        if _isVertical then
            table.sort(_points, function(left, right)
                return left.y < right.y
            end)
        else
            table.sort(_points, function(left, right)
                return left.x < right.x
            end)
        end
    end
    function instance:getIndexAndDistanceOfSegmentClosestToPoint(x, y)
        local numberOfPoints = #_points
        if numberOfPoints < 1 then return nil end

        local lowestDistance
        local lowestDistanceIndex = 1

        for i = 1, numberOfPoints do
            local point = _points[i]
            local nextPoint = _points[i + 1]

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
    function instance:getIndexAndDistanceOfPointClosestToPoint(x, y)
        local numberOfPoints = #_points
        if numberOfPoints < 1 then return nil end

        local lowestDistance
        local lowestDistanceIndex = 1

        for i = 1, numberOfPoints do
            local point = _points[i]

            local distance = distanceBetweenTwoPoints(x, y, point.x, point.y)
            lowestDistance = lowestDistance or distance

            if distance and distance < lowestDistance then
                lowestDistance = distance
                lowestDistanceIndex = i
            end
        end

        return lowestDistanceIndex, lowestDistance
    end
    function instance:getIndexOfPointOrSegmentClosestToPointWithinDistance(x, y, distance)
        local index
        local indexIsPoint
        local segmentIndex, segmentDistance = instance:getIndexAndDistanceOfSegmentClosestToPoint(x, y)
        local pointIndex, pointDistance = instance:getIndexAndDistanceOfPointClosestToPoint(x, y)
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

    function instance:drawSegment(index, color)
        local point = _points[index]
        local nextPoint = _points[index + 1]
        if point == nil then return end
        if nextPoint == nil then return end

        instance:setColor(color)
        instance:drawLine(point.x, point.y, nextPoint.x, nextPoint.y, true)
    end
    function instance:drawPoint(index, color, size, asSquare)
        local point = _points[index]
        if point == nil then return end

        instance:setColor(color)
        if asSquare then
            instance:drawRectangle(point.x - 1, point.y - 1, size, size, true)
        else
            instance:drawCircle(point.x, point.y, size, true, true)
        end
    end

    return instance
end

return PolyLine