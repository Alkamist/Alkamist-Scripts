package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Lua = require "Various Functions.Lua Functions"
local Reaper = require "Various Functions.Reaper Functions"



------------------- Class -------------------

local PitchPoint = {}

function PitchPoint:new(takeGUID, index, time, pitch, rms)
    local object = {}

    object.takeGUID = takeGUID or nil
    local take = reaper.GetMediaItemTakeByGUID(0, takeGUID) or nil

    object.index = index or 0
    object.time = time - reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS") or 0
    object.pitch = pitch or 0
    object.rms = rms or 0

    object.correctedPitch = object.correctedPitch or pitch or 0

    setmetatable(object, self)
    self.__index = self
    return object
end



function PitchPoint:getTake()
    return reaper.GetMediaItemTakeByGUID(0, self.takeGUID)
end

function PitchPoint:getPlayrate()
    return reaper.GetMediaItemTakeInfo_Value(self:getTake(), "D_PLAYRATE")
end

function PitchPoint:getEnvelope()
    local pitchEnvelope = reaper.GetTakeEnvelopeByName(self:getTake(), "Pitch")
    if not pitchEnvelope or not reaper.ValidatePtr2(0, pitchEnvelope, "TrackEnvelope*") then
        reaper.Main_OnCommand(41612, 0) -- Take: Toggle take pitch envelope
        pitchEnvelope = reaper.GetTakeEnvelopeByName(self:getTake(), "Pitch")
    end

    return pitchEnvelope
end



------------------- Sorting -------------------
function PitchPoint.findPointByTime(time, pitchPoints, findLeft)
    local numPitchPoints = #pitchPoints

    if numPitchPoints < 1 then
        return nil, 0
    end

    local firstPoint = pitchPoints[1]
    local lastPoint = pitchPoints[numPitchPoints]
    local totalTime = lastPoint.time - firstPoint.time

    local bestGuessIndex = math.floor(numPitchPoints * time / totalTime)
    bestGuessIndex = Lua.clamp(bestGuessIndex, 1, numPitchPoints)

    local guessPoint = pitchPoints[bestGuessIndex]
    local prevGuessError = math.abs(guessPoint.time - time)
    local prevGuessIsLeftOfTime = guessPoint.time <= time

    repeat
        guessPoint = pitchPoints[bestGuessIndex]

        local guessError = math.abs(guessPoint.time - time)
        local guessIsLeftOfTime = guessPoint.time <= time

        if guessIsLeftOfTime then
            -- You are going right and the target is still to the right.
            if prevGuessIsLeftOfTime then
                bestGuessIndex = bestGuessIndex + 1

            -- You were going left and passed the target.
            else
                if guessError < prevGuessError then
                    return guessPoint, bestGuessIndex
                else
                    return pitchPoints[bestGuessIndex + 1], bestGuessIndex + 1
                end
            end

        else
            -- You are going left and the target is still to the left.
            if not prevGuessIsLeftOfTime then
                bestGuessIndex = bestGuessIndex - 1

            -- You were going right and passed the target.
            else
                if guessError < prevGuessError then
                    return guessPoint, bestGuessIndex
                else
                    return pitchPoints[bestGuessIndex - 1], bestGuessIndex - 1
                end
            end

        end

        prevGuessError = guessError
        prevGuessIsLeftOfTime = guessIsLeftOfTime

    until bestGuessIndex < 1 or bestGuessIndex > numPitchPoints

    if bestGuessIndex < 1 then
        return firstPoint, 1

    elseif bestGuessIndex > numPitchPoints then
        return lastPoint, numPitchPoints
    end

    return firstPoint, 1
end



------------------- Helpful Functions -------------------
function PitchPoint.getAveragePitch(pitchPoints)
    local pitchAverage = 0

    for key, point in ipairs(pitchPoints) do
        pitchAverage = pitchAverage + point.pitch
    end

    return pitchAverage / #pitchPoints
end

function PitchPoint.getPitchPointsInTimeRange(pitchPoints, leftTime, rightTime)
    local newPoints = {}
    local dataIndex = 1
    for key, point in ipairs(pitchPoints) do
        if point.time >= leftTime and point.time <= rightTime then
            newPoints[dataIndex] = point
            dataIndex = dataIndex + 1
        end
    end

    return newPoints
end

function PitchPoint.getRawPointsByPitchDataStringInTimeRange(pitchDataString, playrate, stretchMarkers, leftTime, rightTime)
    local rawPoints = {}
    local pointIndex = 1
    local stretchMarkerIndex = 1
    local playratesMatch = false
    local stretchMarkersMatch = false
    local recordPitchData = false
    local skipThisLine = false

    for line in pitchDataString:gmatch("[^\r\n]+") do

        --------------------- Playrate ---------------------

        local prevPlayrate = tonumber(line:match("PLAYRATE ([%.%-%d]+)"))
        if Lua.floatsAreEqual( prevPlayrate, playrate, 0.0001 ) then
            playratesMatch = true
        end



        --------------------- Stretch Markers ---------------------

        if line:match("<STRETCHMARKERS") and playratesMatch then
            compareStretchMarkers = true
            stretchMarkersMatch = true
            stretchMarkerIndex = 1
            skipThisLine = true
        end

        if line:match(">") and compareStretchMarkers then
            compareStretchMarkers = false

            -- There are no stretch markers in the string or the input.
            if stretchMarkerIndex == 1 and #stretchMarkers == 0 then
                stretchMarkersMatch = true

            -- There are more input stretch markers than there are string stretch markers.
            elseif #stretchMarkers ~= stretchMarkerIndex - 1 then
                stretchMarkersMatch = false
            end
        end

        if compareStretchMarkers and not skipThisLine then
            local pos =    tonumber( line:match("    ([%.%-%d]+)") )
            local srcPos = tonumber( line:match("    [%.%-%d]+ ([%.%-%d]+)") )

            local currentStretchMarker = stretchMarkers[stretchMarkerIndex]

            if currentStretchMarker then

                if not Lua.floatsAreEqual( currentStretchMarker.pos, pos, 0.0001 ) then
                    stretchMarkersMatch = false
                end

                if not Lua.floatsAreEqual( currentStretchMarker.srcPos, srcPos, 0.0001 ) then
                    stretchMarkersMatch = false
                end

            -- There are less input stretch markers than there are string stretch markers.
            else
                stretchMarkersMatch = false
            end

            stretchMarkerIndex = stretchMarkerIndex + 1
        end



        --------------------- Pitch Data ---------------------

        if line:match("<PITCHDATA") and playratesMatch and stretchMarkersMatch then
            recordPitchData = true
            skipThisLine = true
        end

        if line:match(">") and recordPitchData then
            recordPitchData = false
            playratesMatch = false
            stretchMarkersMatch = false
        end

        if recordPitchData and not skipThisLine then
            local point = {}

            for value in line:gmatch("[%.%-%d]+") do
                table.insert(point, tonumber(value))
            end

            if #point > 1 then
                if point[1] >= leftTime and point[1] <= rightTime then
                    rawPoints[pointIndex] = {}

                    rawPoints[pointIndex].index = pointIndex
                    rawPoints[pointIndex].time = point[1]
                    rawPoints[pointIndex].pitch = point[2]
                    rawPoints[pointIndex].rms = point[3]

                    pointIndex = pointIndex + 1
                end
            end
        end

        skipThisLine = false
    end

    return rawPoints
end

function PitchPoint.getPitchPointsByTakeNameInTimeRange(takeGUID, takeName, playrate, stretchMarkers, leftTime, rightTime)
    local _, extState = reaper.GetProjExtState(0, "Alkamist_PitchCorrection", takeName)

    local pitchPoints = {}
    local pointIndex = 1
    local recordPitchData = false

    local rawPoints = PitchPoint.getRawPointsByPitchDataStringInTimeRange(extState, playrate, stretchMarkers, leftTime, rightTime)

    for pointIndex, point in ipairs(rawPoints) do
        pitchPoints[pointIndex] = PitchPoint:new(takeGUID, pointIndex, point.time, point.pitch, point.rms)
    end

    return pitchPoints
end

function PitchPoint.getPitchPointsByTakeGUID(takeGUID)
    local take = reaper.GetMediaItemTakeByGUID(0, takeGUID)
    local takeName = reaper.GetTakeName(take)
    local item = reaper.GetMediaItemTake_Item(take)

    local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local itemStartOffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local stretchMarkers = Reaper.getStretchMarkers(take)

    local pointsLeftBound = itemStartOffset
    local pointsRightBound = itemStartOffset + itemLength

    return PitchPoint.getPitchPointsByTakeNameInTimeRange(takeGUID, takeName, playrate, stretchMarkers, pointsLeftBound, pointsRightBound)
end

return PitchPoint