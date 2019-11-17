local reaper = reaper
local math = math
local table = table
local pairs = pairs

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Json = require("dkjson")
local Proxy = require("Proxy")

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

local TimeSeries = {}
function TimeSeries:new(parameters)
    local parameters = parameters or {}
    local self = parameters.from or {}

    self.leftBound = 0
    self.rightBound = 0
    self.points = {}

    function self:sortPoints()
        local points = self.points
        table.sort(points, function(left, right)
            return left.time < right.time
        end)
    end
    function self:clearPointsWithinTimeRange(leftTime, rightTime)
        local points = self.points
        arrayRemove(points, function(i, j)
            return points[i].time >= leftTime and points[i].time <= rightTime
        end)
    end
    function self:removeDuplicatePoints(tolerance)
        local tolerance = tolerance or 0.0001
        local newPoints = {}
        local points = self.points
        for i = 1, #points do
            local point = points[i]
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
        self.points = newPoints
    end
    function self:encodeAsString(pointMembers)
        local points = self.points
        local numberOfPoints = #points
        local numberOfMembers = #pointMembers
        local saveTable = {
            leftBound = self.leftBound,
            rightBound = self.rightBound,
            numberOfPoints = numberOfPoints,
            points = {}
        }
        for name, defaultValue in pairs(pointMembers) do
            for i = 1, numberOfPoints do
                local point = points[i]
                local value = point[name]
                if value == nil then value = defaultValue end
                if value == nil then value = 0 end
                saveTable.points[name] = saveTable.points[name] or {}
                saveTable.points[name][i] = value
            end
        end
        return Json.encode(saveTable, { indent = true })
    end
    function self:decodeFromString(stringToDecode, pointMembers)
        local decodedTable = Json.decode(stringToDecode)
        self.leftBound = decodedTable.leftBound
        self.rightBound = decodedTable.rightBound
        self.points = {}
        local numberOfPoints = decodedTable.numberOfPoints
        for name, defaultValue in pairs(pointMembers) do
            for i = 1, numberOfPoints do
                local pointMember = decodedTable.points[name]
                local value = defaultValue
                if pointMember then
                    value = pointMember[i]
                    if value == nil then value = defaultValue end
                    if value == nil then value = 0 end
                end
                self.points[i] = self.points[i] or {}
                self.points[i][name] = value
            end
        end
    end

    return Proxy:new(self, parameters)
end

return TimeSeries