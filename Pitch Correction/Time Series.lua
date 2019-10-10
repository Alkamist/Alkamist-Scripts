local Lua = require "Various Functions.Lua Functions"

local TimeSeries = {}
function TimeSeries:new(object)
    local object = object or {}
    setmetatable(object, { __index = self })
    object:init()
    return object
end

function TimeSeries:init()
end

function TimeSeries:getSaveString(saveMembers, saveTitle)
    local keyString = ""
    for _, member in pairs(saveMembers) do
        keyString = keyString .. member.name .. " "
    end

    local dataString = ""

    -- Build the data string.
    for _, point in ipairs(self.points) do
        for _, member in pairs(saveMembers) do
            -- Initialize with defaults for any member values that are not present.
            if not point[member.name] then
                point[member.name] = member.default
            end

            dataString = dataString .. tostring(point[member.name]) .. " "
        end

        dataString = dataString .. "\n"
    end

    local saveString = "<" .. saveTitle .. " " .. keyString .. "\n" ..
                       dataString ..
                       ">\n"

    return saveString
end

function TimeSeries:loadFromString(saveString, loadMembers)
    self.points = {}
    local title = ""
    local nameKeys = {}

    local lines = Lua.getStringLines(saveString)
    for lineIndex, line in ipairs(lines) do
        -- The first line is the title and member line.
        if lineIndex == 1 then
            local nameIndex = 1
            for name in string.gmatch(line:match("[^<]+"), "[%a]+") do
                -- The first name is the title.
                if nameIndex == 1 then
                    title = name
                else
                    table.insert(nameKeys, name)
                end

                nameIndex = nameIndex + 1
            end
        -- The rest of the lines have data.
        else
            -- Unless you find the symbol to end the series.
            if line:match(">") then break end

            -- Build a point from the values you find and add it to the output.
            local point = {}
            local valueIndex = 1
            for value in string.gmatch(line, "[%.%-%d]+") do
                local valueName = nameKeys[valueIndex]

                -- Only insert the value into the point if it is one of the load members.
                for _, member in pairs(loadMembers) do
                    if valueName == member.name then
                        point[valueName] = value
                        break
                    end
                end

                valueIndex = valueIndex + 1
            end

            -- Set any load members that weren't present to the defaults.
            for _, member in pairs(loadMembers) do
                if point[member.name] == nil then
                    point[member.name] = member.default
                end
            end

            table.insert(self.points, point)
        end
    end
end

function TimeSeries:getFirstPointAfterTime(time)
    local guessIndex = 1
    if self.points[guessIndex].time >= time then return self.points[guessIndex] end

    local numPoints = #self.points
    local scanIncrement = math.floor(0.1 * numPoints)

    -- Scan the points in increments to find when we pass the time.
    while true do
        guessIndex = guessIndex + scanIncrement

        if self.points[guessIndex].time >= time then break end
    end

    -- Back up and find the exact point that crosses the time.
    while true do
        guessIndex = guessIndex - 1

        if self.points[guessIndex].time < time then
            guessIndex = guessIndex + 1
            break
        end
    end

    return self.points[guessIndex]
end

function TimeSeries:getPointsInTimeRange(timeRange)
    if timeRange.rightTime == nil then return {} end

    local pointsInTimeRange = TimeSeries:new()
    local point = self:getFirstPointAfterTime(timeRange.leftTime)

    while true do
        table.insert(pointsInTimeRange, point)
        point = point.next
        if point == nil then break end
        if point.time > timeRange.rightTime then break end
    end

    return pointsInTimeRange
end

function TimeSeries:sort()
    table.sort(self.points, function(a, b)
        return a.time < b.time
    end)
end

return TimeSeries