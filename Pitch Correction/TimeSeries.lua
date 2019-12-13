local Array = require("Array")

local math = math
local table = table

local TimeSeries = {}

function TimeSeries:sortPoints()
    table.sort(self, function(left, right)
        local leftTime = left.time
        local rightTime = right.time
        if leftTime and rightTime then
            return left.time < right.time
        end
    end)
end
function TimeSeries:clearPointsWithinTimeRange(leftTime, rightTime)
    Array.remove(self, function(i, j)
        return self[i].time >= leftTime and self[i].time <= rightTime
    end)
end
function TimeSeries:removeDuplicatePoints(tolerance)
    local tolerance = tolerance or 0.0001
    local newPoints = {}
    for i = 1, #self do
        local point = self[i]
        local pointIsDuplicate = false
        for j = 1, #newPoints do
            if math.abs(point.time - newPoints[j].time) < tolerance then
                pointIsDuplicate = true
            end
        end
        if not pointIsDuplicate then
            newPoints[#newPoints + 1] = point
        end
    end
    return newPoints
end

return TimeSeries