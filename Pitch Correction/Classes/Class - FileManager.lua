package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Lua =    require "Various Functions.Lua Functions"
local Reaper = require "Various Functions.Reaper Functions"
require "Various Functions.Table IO"



local FileManager = {}

function FileManager:new(o)
    o = o or {}

    setmetatable(o, self)
    self.__index = self

    o.data = o.data or ""
    o.lines = o.lines or {}
    o.headerLineNumbers = o.headers or {}
    o:documentData()

    return o
end



function FileManager:documentData()
    self.lines = {}
    self.headerLineNumbers = {}

    local lineIndex = 1
    local searchIndex = 1

    repeat

        local line = string.match(self.data, "([^\r\n]+)", searchIndex)
        if line == nil then break end

        self.lines[lineIndex] = line

        if line:sub(1, 1) == "<" then

            local title = line:match("<(%a+)")
            self.headerLineNumbers[title] = self.headerLineNumbers[title] or {}

            table.insert(self.headerLineNumbers[title], lineIndex)

        end

        lineIndex = lineIndex + 1
        searchIndex = searchIndex + string.len(line) + 1

    until false
end



function FileManager:getPitchPoints(pitchGroup, stretchMarkers)
    if self.headerLineNumbers["PITCHDATA"] == nil then return {} end

    local pitchPoints = {}
    local tempMarkers = stretchMarkers or {}

    if #tempMarkers == 0 then
        table.insert( tempMarkers , {
            pos = 0.0,
            srcPos = Reaper.getSourcePosition(pitchGroup.take, 0.0),
            rate = 1.0
        } )
    end

    for index, marker in ipairs(tempMarkers) do

        local nextMarker = nil
        if index < #tempMarkers then
            nextMarker = tempMarkers[index + 1]
        end

        local leftBound = marker.srcPos
        local rightBound = pitchGroup.takeSourceLength
        if nextMarker then rightBound = nextMarker.srcPos end

        local startOffset = pitchGroup.startOffset
        local scaleRate = 1.0
        local startPos = 0.0

        if marker then
            startOffset = marker.srcPos
            scaleRate = marker.rate
            startPos = marker.pos
        end

        for headerIndex, lineNumber in ipairs(self.headerLineNumbers["PITCHDATA"]) do

            local headerValues = self:getValues(self.lines[lineNumber])
            local headerLeft = headerValues[1] or 0.0
            local headerRight = headerValues[2] or pitchGroup.length * pitchGroup.playrate

            if Lua.rangesOverlap( { left = leftBound, right = rightBound } , { left = headerLeft, right = headerRight } ) then

                local pointData = self:getDataFromHeader("PITCHDATA", headerIndex, { left = leftBound, right = rightBound } )

                for pointIndex, point in ipairs(pointData) do

                    local pointTime = point[1]
                    local scaledPointTime = startPos + (pointTime - startOffset) / scaleRate

                    if scaledPointTime >= 0.0 and scaledPointTime <= pitchGroup.length * pitchGroup.playrate then

                        table.insert(pitchPoints, {

                            time =  pointTime,
                            pitch = point[2],
                            rms =   point[3],
                            relativeTime = scaledPointTime / pitchGroup.playrate,
                            envelopeTime = scaledPointTime,
                            markerRate = scaleRate

                        } )

                    end
                end
            end
        end
    end

    return pitchPoints
end

function FileManager:getPitchGroups()
    if self.headerLineNumbers["PITCHDATA"] == nil then return {} end

    local pitchGroups = {}
    local groupIndex = 1

    for headerIndex, lineNumber in ipairs(self.headerLineNumbers["PITCHDATA"]) do

        local headerValues = self:getValues(self.lines[lineNumber])
        local headerLeft = headerValues[1]
        local headerRight = headerValues[2]

        pitchGroups[groupIndex] = {

            startOffset = headerLeft,
            length = headerRight - headerLeft,
            points = {}

        }

        local pointData = self:getDataFromHeader("PITCHDATA", headerIndex)

        for pointIndex, point in ipairs(pointData) do

            local pointTime = point[1]
            local scaledPointTime = pointTime - headerLeft

            table.insert(pitchGroups[groupIndex].points, {

                time =  pointTime,
                pitch = point[2],
                rms =   point[3],
                relativeTime = scaledPointTime,
                envelopeTime = scaledPointTime,
                markerRate = 1.0

            } )
        end

        groupIndex = groupIndex + 1
    end

    return pitchGroups
end

function FileManager:getDataFromHeader(headerTitle, headerNumber, timeRange)
    local lineNumber = self.headerLineNumbers[headerTitle][headerNumber] + 1

    local valueChunks = {}

    repeat

        local line = self.lines[lineNumber]
        if line:sub(1, 1) == ">" then break end

        if timeRange then
            local timeValue = tonumber( line:match("([%.%-%d]+)") )

            if timeValue then
                if timeRange.left and timeRange.right then
                    if timeValue >= timeRange.left and timeValue <= timeRange.right then
                        table.insert(valueChunks, self:getValues(line))
                    end
                end
            end
        else
            table.insert(valueChunks, self:getValues(line))
        end

        lineNumber = lineNumber + 1

    until false

    return valueChunks
end



function FileManager:getValues(line)
    local values = {}

    for value in string.gmatch(line, "[%.%-%d]+") do
        table.insert( values, tonumber(value) )
    end

    return values
end

function FileManager.fileExists(fileName)
    local f = io.open(fileName, "rb")
    if f then f:close() end
    return f ~= nil
end

function FileManager.getFileLines(fileName)
    if not FileManager.fileExists(fileName) then return {} end

    local lines = {}

    for line in io.lines(fileName) do
        lines[#lines + 1] = line
    end

    return lines
end



function FileManager.savePitchGroup(pitchGroup)
    local fullFileName = reaper.GetProjectPath("") .. "\\" ..
                         pitchGroup.takeFileName .. ".pitch"

    local file, err = io.open(fullFileName, "w")


    local pitchString = ""
    local pitchKeyString = ""

    for pointIndex, point in ipairs(pitchGroup.points) do

        for key, value in pairs(pitchGroup.points[1]) do
            if pointIndex == 1 then
                pitchKeyString = pitchKeyString .. key .. " "
            end

            pitchString = pitchString .. tostring(point[key]) .. " "
        end

        pitchString = pitchString .. "\n"

    end


    local saveString = "LEFTBOUND " .. tostring(pitchGroup.startOffset) .. "\n" ..

                       "RIGHTBOUND " .. tostring(pitchGroup.startOffset + pitchGroup.length) .. "\n" ..

                       "<PITCH " .. pitchKeyString .. "\n" ..
                           pitchString ..
                       ">\n"


    file:write(saveString)
end

function FileManager.loadPitchGroup(fileName)
    local fullFileName = reaper.GetProjectPath("") .. "\\" .. fileName

    local lines = FileManager.getFileLines(fullFileName)

    local pitchGroup = {}

    local headerLeft = nil
    local headerRight = nil
    local keys = {}
    local recordPoints = false
    local pointIndex = 1

    for lineNumber, line in ipairs(lines) do

        headerLeft = headerLeft or tonumber( line:match("LEFTBOUND ([%.%-%d]+)") )
        headerRight = headerRight or tonumber( line:match("RIGHTBOUND ([%.%-%d]+)") )

        if headerLeft and headerRight and not pitchGroup.startOffset then

            pitchGroup = {

                startOffset = headerLeft,
                length = headerRight - headerLeft,
                points = {}

            }

        end

        if pitchGroup.startOffset then

            if line:match("<PITCH") then
                recordPoints = true
                pointIndex = 1

                for key in string.gmatch(line, " (%a+)") do
                    table.insert(keys, key)
                end
            end

            if line:match(">") then
                recordPoints = false
                keys = {}
            end

            if recordPoints then

                pitchGroup.points[pointIndex] = {}
                local lineValues = FileManager:getValues(line)

                if #lineValues >= #keys then
                    for index, key in ipairs(keys) do
                        pitchGroup.points[pointIndex][key] = lineValues[index]
                    end

                    pointIndex = pointIndex + 1
                end
            end
        end
    end

    return pitchGroup
end

return FileManager