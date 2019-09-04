package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Lua =    require "Various Functions.Lua Functions"
local Reaper = require "Various Functions.Reaper Functions"



local FileManager = {}



function FileManager.getValues(line)
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



function FileManager.getPitchPointsFromExtState(pitchGroup)
    local pointString = reaper.GetExtState("Alkamist_PitchCorrection", "PITCHDATA")

    local pitchPoints = {}

    for line in pointString:gmatch("([^\r\n]+)") do

        local values = FileManager.getValues(line)

        local pointTime = values[1] - pitchGroup.startOffset
        local sourceTime = Reaper.getSourcePosition(pitchGroup.take, pointTime)

        local point = {

            time = pointTime,
            sourceTime = sourceTime,
            pitch = values[2],
            rms = values[3]

        }

        table.insert(pitchPoints, point)
    end

    return pitchPoints
end

function FileManager.savePitchGroup(pitchGroup)
    local fullFileName = reaper.GetProjectPath("") .. "\\" ..
                         pitchGroup.takeFileName .. ".pitch"

    local file, err = io.open(fullFileName, "a")



    local pitchKeyString = "sourceTime pitch rms"
    local pitchString = ""

    for pointIndex, point in ipairs(pitchGroup.points) do
        pitchString = pitchString .. tostring(point.sourceTime) .. " " ..
                                     tostring(point.pitch) .. " " ..
                                     tostring(point.rms) .. "\n"
    end


    local saveString = "LEFTBOUND " .. tostring(pitchGroup.startOffset) .. "\n" ..

                       "RIGHTBOUND " .. tostring(pitchGroup.startOffset + pitchGroup.length) .. "\n" ..

                       "<PITCH " .. pitchKeyString .. "\n" ..
                       pitchString ..
                       ">\n"


    file:write(saveString)
end

function FileManager.loadPitchPoints(fileName, pitchGroup)
    local fullFileName = reaper.GetProjectPath("") .. "\\" .. fileName

    local lines = FileManager.getFileLines(fullFileName)

    pitchGroup.points = {}

    local headerLeft = nil
    local headerRight = nil
    local keys = {}
    local recordPoints = false
    local pointIndex = 1

    local leftBound = Reaper.getSourcePosition(pitchGroup.take, 0.0)
    local rightBound = Reaper.getSourcePosition(pitchGroup.take, pitchGroup.length)

    for lineNumber, line in ipairs(lines) do

        headerLeft = headerLeft or tonumber( line:match("LEFTBOUND ([%.%-%d]+)") )
        headerRight = headerRight or tonumber( line:match("RIGHTBOUND ([%.%-%d]+)") )

        if line:match(">") then
            recordPoints = false
            headerLeft = nil
            headerRight = nil
            keys = {}
        end

        if headerLeft and headerRight then

            if Lua.rangesOverlap( { left = headerLeft, right = headerRight },
                                  { left = leftBound, right = rightBound } ) then

                if line:match("<PITCH") then
                    recordPoints = true

                    for key in string.gmatch(line, " (%a+)") do
                        table.insert(keys, key)
                    end
                end

                if recordPoints then

                    local lineValues = FileManager.getValues(line)

                    if #lineValues >= #keys then
                        local point = {}

                        for index, key in ipairs(keys) do
                            point[key] = lineValues[index]
                        end

                        if point.sourceTime >= leftBound and point.sourceTime <= rightBound then
                            pitchGroup.points[pointIndex] = point
                            pitchGroup.points[pointIndex].time = Reaper.getRealPosition(pitchGroup.take, pitchGroup.points[pointIndex].sourceTime)

                            pointIndex = pointIndex + 1
                        end
                    end
                end
            end
        end
    end
end

function FileManager.loadAllPitchGroups(fileName)
    local fullFileName = reaper.GetProjectPath("") .. "\\" .. fileName

    local lines = FileManager.getFileLines(fullFileName)

    local pitchGroups = {}

    local headerLeft = nil
    local headerRight = nil
    local keys = {}
    local recordPoints = false
    local pointIndex = 1
    local groupIndex = 1

    for lineNumber, line in ipairs(lines) do

        headerLeft = headerLeft or tonumber( line:match("LEFTBOUND ([%.%-%d]+)") )
        headerRight = headerRight or tonumber( line:match("RIGHTBOUND ([%.%-%d]+)") )

        if headerLeft and headerRight then

            if line:match("<PITCH") then
                pitchGroups[groupIndex] = {

                    startOffset = headerLeft,
                    length = headerRight - headerLeft,
                    points = {}

                }

                recordPoints = true
                pointIndex = 1

                for key in string.gmatch(line, " (%a+)") do
                    table.insert(keys, key)
                end
            end

            if line:match(">") then
                groupIndex = groupIndex + 1
                recordPoints = false
                headerLeft = nil
                headerRight = nil
                keys = {}
            end

            if recordPoints then

                local lineValues = FileManager.getValues(line)

                if #lineValues >= #keys then
                    local point = {}

                    for index, key in ipairs(keys) do
                        point[key] = lineValues[index]
                    end

                    local currentPoint = pitchGroups[groupIndex].points[pointIndex]

                    currentPoint = point
                    currentPoint.time = currentPoint.sourceTime

                    pointIndex = pointIndex + 1
                end
            end
        end
    end

    return pitchGroups
end

return FileManager