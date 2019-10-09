local TimeSeries = {}

function TimeSeries.getFirstPointAfterTime(time, points)
    local guessIndex = 1
    if points[guessIndex].time >= time then return points[guessIndex] end

    local numPoints = #points
    local scanIncrement = math.floor(0.1 * numPoints)

    -- Scan the points in increments to find when we pass the time.
    while true do
        guessIndex = guessIndex + scanIncrement

        if points[guessIndex].time >= time then break end
    end

    -- Back up and find the exact point that crosses the time.
    while true do
        guessIndex = guessIndex - 1

        if points[guessIndex].time < time then
            guessIndex = guessIndex + 1
            break
        end
    end

    return points[guessIndex]
end

function TimeSeries.getPointsInTimeRange(timeRange, points)
    if timeRange.rightTime == nil then return {} end

    local pointsInTimeRange = {}
    local point = TimeSeries.getFirstPointAfterTime(timeRange.leftTime, points)

    while true do
        table.insert(pointsInTimeRange, point)
        point = point.next
        if point == nil then break end
        if point.time > timeRange.rightTime then break end
    end

    return pointsInTimeRange
end

return TimeSeries