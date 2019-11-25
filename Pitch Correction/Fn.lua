local reaper = reaper
local table = table
local math = math
local pairs = pairs
local gfx = gfx

local Fn = {}

-- Used to make initializing objects easier.
function Fn.makeNew(states, base, object)
    local object = object or {}
    for k, v in pairs(states) do if
        object[k] == nil then
            object[k] = v
        end
    end
    for k, v in pairs(base) do
        if object[k] == nil and k ~= "new" then
            object[k] = v
        end
    end
    return object
end
function Fn.callWithChanges(fn, defaults, changes)
    local storedDefaults = {}
    for k, v in pairs(changes) do
        storedDefaults[k] = defaults[k]
        defaults[k] = v
    end
    local output = fn(defaults)
    for k, v in pairs(storedDefaults) do
        defaults[k] = v
    end
    return output
end

-- Efficiently removes entries from an array based on some condition function.
function Fn.arrayRemove(t, fn)
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
end
-- Inserts something into an array based on a sorting function.
-- Returns the index that the thing was inserted at.
function Fn.arrayInsert(t, newThing, sortFn)
    local amount = #t
    if amount == 0 then
        t[1] = newThing
        return 1
    end

    for i = 1, amount do
        local thing = t[i]
        if not sortFn(thing, newThing) then
            table.insert(t, i, newThing)
            return i
        end
    end

    t[amount + 1] = newThing
    return amount + 1
end

function Fn.invertTable(t)
    local invertedTable = {}
    for k, v in pairs(t) do
        invertedTable[v] = k
    end
    return invertedTable
end
function Fn.getMinimumDistanceBetweenPointAndLineSegment(pointX, pointY, lineX1, lineY1, lineX2, lineY2)
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
function Fn.getDistanceBetweenTwoPoints(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end
function Fn.getIndexAndDistanceOfSegmentClosestToPoint(points, xName, yName, x, y)
    local numberOfPoints = #points
    if numberOfPoints < 1 then return nil end
    local getDistance = Fn.getMinimumDistanceBetweenPointAndLineSegment

    local lowestDistance
    local lowestDistanceIndex = 1

    for i = 1, numberOfPoints do
        local point = points[i]
        local nextPoint = points[i + 1]

        local distance
        if nextPoint then
            distance = getDistance(x, y, point[xName], point[yName], nextPoint[xName], nextPoint[yName])
        end
        lowestDistance = lowestDistance or distance

        if distance and distance < lowestDistance then
            lowestDistance = distance
            lowestDistanceIndex = i
        end
    end

    return lowestDistanceIndex, lowestDistance
end
function Fn.getIndexAndDistanceOfPointClosestToPoint(points, xName, yName, x, y)
    local numberOfPoints = #points
    if numberOfPoints < 1 then return nil end
    local getDistance = Fn.getDistanceBetweenTwoPoints

    local lowestDistance
    local lowestDistanceIndex = 1

    for i = 1, numberOfPoints do
        local point = points[i]

        local distance = getDistance(x, y, point[xName], point[yName])
        lowestDistance = lowestDistance or distance

        if distance and distance < lowestDistance then
            lowestDistance = distance
            lowestDistanceIndex = i
        end
    end

    return lowestDistanceIndex, lowestDistance
end
function Fn.getIndexOfPointOrSegmentClosestToPointWithinDistance(points, xName, yName, x, y, distance)
    local index
    local indexIsPoint
    local segmentIndex, segmentDistance = Fn.getIndexAndDistanceOfSegmentClosestToPoint(points, xName, yName, x, y)
    local pointIndex, pointDistance = Fn.getIndexAndDistanceOfPointClosestToPoint(points, xName, yName, x, y)
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
function Fn.pointIsInsideBounds(pX, pY, x1, y1, x2, y2)
    return pX >= x1 and pX <= x2
       and pY >= y1 and pY <= y2
end

return Fn