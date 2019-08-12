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

    if bestGuessIndex > 1 and bestGuessIndex < numPitchPoints then
        repeat
            local lowerGuess = pitchPoints[bestGuessIndex - 1]
            local guessPoint = pitchPoints[bestGuessIndex]
            local higherGuess = pitchPoints[bestGuessIndex + 1]

            local lowerGuessDist = math.abs(time - lowerGuess.time)
            local guessPointDist = math.abs(time - guessPoint.time)
            local higherGuessDist = math.abs(time - higherGuess.time)

            local guessPointIsClosest = guessPointDist <= lowerGuessDist and guessPointDist <= higherGuessDist

            if guessPointIsClosest or bestGuessIndex == 2 or bestGuessIndex == numPitchPoints - 1 then
                break
            end

            if lowerGuessDist < guessPointDist then
                bestGuessIndex = bestGuessIndex - 1

            elseif higherGuessDist < guessPointDist then
                bestGuessIndex = bestGuessIndex + 1

            end
        until guessPointIsClosest

        local guessPoint = pitchPoints[bestGuessIndex]

        if findLeft and guessPoint.time > time then
            return pitchPoints[bestGuessIndex - 1], bestGuessIndex - 1

        elseif not findLeft and guessPoint.time < time then
            return pitchPoints[bestGuessIndex + 1], bestGuessIndex + 1
        end

        return guessPoint, bestGuessIndex

    elseif bestGuessIndex <= 1 and not findLeft then
        return pitchPoints[1], 1

    elseif bestGuessIndex >= numPitchPoints and findLeft then
        return pitchPoints[numPitchPoints], numPitchPoints
    end

    return pitchPoints[numPitchPoints], numPitchPoints
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

function PitchPoint.getPitchPoints(takeGUID)
    local _, extState = reaper.GetProjExtState(0, "Alkamist_PitchCorrection", takeGUID)

    local takePitchPoints = {}
    for line in extState:gmatch("[^\r\n]+") do
        if line:match("PT") then
            local stat = {}
            for value in line:gmatch("[%.%-%d]+") do
                stat[#stat + 1] = tonumber(value)
            end
            takePitchPoints[stat[1]] = PitchPoint:new(takeGUID, stat[1], stat[2], stat[3], stat[4])
        end
    end

    return takePitchPoints
end

return PitchPoint