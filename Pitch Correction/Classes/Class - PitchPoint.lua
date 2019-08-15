package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Lua = require "Various Functions.Lua Functions"



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
function PitchPoint.pairs(pitchPoints)
    local temp = {}
    for key, correction in pairs(pitchPoints) do
        table.insert(temp, {key, correction})
    end

    table.sort(temp, function(pp1, pp2)
        return pp1[2].index < pp2[2].index
    end)

    local i = 0
    local iterator = function()
        i = i + 1

        if temp[i] == nil then
            return nil
        else
            return temp[i][1], temp[i][2]
        end
    end

    return iterator
end

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

    for key, point in PitchPoint.pairs(pitchPoints) do
        pitchAverage = pitchAverage + point.pitch
    end

    return pitchAverage / Lua.getTableLength(pitchPoints)
end

function PitchPoint.getPitchPointsInTimeRange(pitchPoints, leftTime, rightTime)
    local newPoints = {}
    local dataIndex = 1
    for key, point in PitchPoint.pairs(pitchPoints) do
        if point.time >= leftTime and point.time <= rightTime then
            newPoints[dataIndex] = point
            dataIndex = dataIndex + 1
        end
    end

    return newPoints
end

function PitchPoint.getRawPointsByPitchDataStringInTimeRange(pitchDataString, leftTime, rightTime)
    local rawPoints = {}
    local pointIndex = 1
    local recordPitchData = false
    local skipThisLine = false

    for line in pitchDataString:gmatch("[^\r\n]+") do

        if line:match("<PITCHDATA") then
            recordPitchData = true
            skipThisLine = true
        end

        if line:match(">") then
            recordPitchData = false
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

function PitchPoint.getPitchPointsByTakeNameInTimeRange(takeGUID, takeName, leftTime, rightTime)
    local _, extState = reaper.GetProjExtState(0, "Alkamist_PitchCorrection", takeName)

    local pitchPoints = {}
    local pointIndex = 1
    local recordPitchData = false

    local rawPoints = PitchPoint.getRawPointsByPitchDataStringInTimeRange(extState, leftTime, rightTime)

    for pointIndex, point in pairs(rawPoints) do
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
    --local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")

    local pointsLeftBound = itemStartOffset
    local pointsRightBound = itemStartOffset + itemLength

    return PitchPoint.getPitchPointsByTakeNameInTimeRange(takeGUID, takeName, pointsLeftBound, pointsRightBound)
end

return PitchPoint