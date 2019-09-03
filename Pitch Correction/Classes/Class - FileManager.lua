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

        local pointTime = values[1]
        local scaledPointTime = pointTime - pitchGroup.startOffset

        local point = {

            time = pointTime,
            pitch = values[2],
            rms = values[3],
            relativeTime = scaledPointTime,
            envelopeTime = scaledPointTime,
            markerRate = 1.0

        }

        table.insert(pitchPoints, point)
    end

    return pitchPoints
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

    local pitchGroup = { points = {} }

    local headerLeft = nil
    local headerRight = nil
    local keys = {}
    local recordPoints = false
    local pointIndex = 1

    for lineNumber, line in ipairs(lines) do

        headerLeft = headerLeft or tonumber( line:match("LEFTBOUND ([%.%-%d]+)") )
        headerRight = headerRight or tonumber( line:match("RIGHTBOUND ([%.%-%d]+)") )

        if headerLeft and headerRight and not pitchGroup.startOffset then

            pitchGroup.startOffset = headerLeft
            pitchGroup.length = headerRight - headerLeft

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
                local lineValues = FileManager.getValues(line)

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