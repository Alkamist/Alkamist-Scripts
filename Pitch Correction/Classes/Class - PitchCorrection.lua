package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Lua = require "Various Functions.Lua Functions"
local PitchPoint = require "Pitch Correction.Classes.Class - PitchPoint"



-- Pitch correction settings:
local zeroPointSpacing = 0.01
local averageCorrection = 0.0
local modCorrection = 1.0
local driftCorrection = 1.0
local driftCorrectionSpeed = 0.2
local driftMax = 0.5
local zeroPointThreshold = 0.1

-- GET THIS FROM SETTINGS LATER
local minTimePerPoint = 0.02



------------------- Class -------------------
local PitchCorrection = {}

function PitchCorrection:new(leftTime, rightTime, leftPitch, rightPitch)
    local object = {}

    object.leftTime = leftTime or 0
    object.rightTime = rightTime or 0
    object.leftPitch = leftPitch or 0
    object.rightPitch = rightPitch or 0

    setmetatable(object, self)
    self.__index = self
    return object
end

function PitchCorrection:getLength()
    return self.rightTime - self.leftTime
end

function PitchCorrection:getInterval()
    return self.rightPitch - self.leftPitch
end

function PitchCorrection:getPitch(time)
    local length = self:getLength()
    if length > 0 then
        local timeRatio = (time - self.leftTime) / self:getLength()
        local rawPitch = self.leftPitch + self:getInterval() * timeRatio
        return rawPitch
    elseif length < 0 then
        local timeRatio = (time - self.rightTime) / self:getLength()
        local rawPitch = self.rightPitch + self:getInterval() * timeRatio
        return rawPitch
    else
        return self.leftPitch
    end
end

function PitchCorrection:timeIsInside(time)
    return time >= self.leftTime and time <= self.rightTime
        or time <= self.leftTime and time >= self.rightTime
end



------------------- Sorting -------------------
function PitchCorrection.pairs(pitchCorrections)
    local temp = {}
    for key, correction in pairs(pitchCorrections) do
        table.insert(temp, {key, correction})
    end

    table.sort(temp, function(pc1, pc2)
        local pc1GoesFirst = pc1[2].leftTime < pc2[2].leftTime
        if pc1[2].leftTime == pc2[2].leftTime then
            pc1GoesFirst = pc1[2].rightTime > pc2[2].rightTime
        end
        return pc1GoesFirst
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



------------------- Helpful Functions -------------------
function PitchCorrection.correctPitchAverage(point, averagePitch, targetPitch, correctionStrength)
    local averageDeviation = averagePitch - targetPitch
    local pitchCorrection = -averageDeviation * correctionStrength

    point.correctedPitch = point.correctedPitch + pitchCorrection
end

function PitchCorrection.correctPitchMod(point, targetPitch, correctionStrength)
    local modDeviation = point.correctedPitch - targetPitch
    local pitchCorrection = -modDeviation * correctionStrength

    point.correctedPitch = point.correctedPitch + pitchCorrection
end

function PitchCorrection.correctPitchDrift(point, pointIndex, pitchPoints, targetPitch, correctionStrength, correctionSpeed)
    local maxDriftPoints = math.ceil(correctionSpeed / minTimePerPoint)

    local driftAverage = 0
    local numDriftPoints = 0
    for i = 1, maxDriftPoints do
        local accessIndex = pointIndex + i - math.floor(maxDriftPoints * 0.5)

        if accessIndex >= 1 and accessIndex <= #pitchPoints then
            local driftPoint = pitchPoints[accessIndex]
            local correctionRadius = correctionSpeed * 0.5

            if driftPoint.time >= point.time - correctionRadius
            and driftPoint.time <= point.time + correctionRadius then
                driftAverage = driftAverage + driftPoint.pitch

                numDriftPoints = numDriftPoints + 1
            end
        end
    end

    if numDriftPoints > 0 then
        driftAverage = driftAverage / numDriftPoints
    end

    local pitchDrift = driftAverage - targetPitch
    --local pitchDrift = point.pitch - driftAverage
    local pitchCorrection = -pitchDrift * correctionStrength

    point.correctedPitch = point.correctedPitch + pitchCorrection
end

function PitchCorrection.addPitchCorrectionsToEnvelope(pitchEnvelope, playrate, takePitchPoints)
    local previousPoint = takePitchPoints[1]
    for key, point in PitchPoint.pairs(takePitchPoints) do
        local timePassedSinceLastPoint = point.time - previousPoint.time

        -- If a certain amount of time has passed since the last point, add zero value edge points in that space.
        if point.index > 1 and zeroPointThreshold then
            if timePassedSinceLastPoint >= zeroPointThreshold then
                local zeroPoint1Time = previousPoint.time + zeroPointSpacing
                reaper.InsertEnvelopePoint(pitchEnvelope, zeroPoint1Time * playrate, 0, 0, 0, false, true)
                local zeroPoint2Time = point.time - zeroPointSpacing
                reaper.InsertEnvelopePoint(pitchEnvelope, zeroPoint2Time * playrate, 0, 0, 0, false, true)
            end
        end

        -- Add envelope points with the correction value.
        reaper.InsertEnvelopePoint(pitchEnvelope, point.time * playrate, point.correctedPitch - point.pitch, 0, 0, false, true)

        previousPoint = point
    end
end

function PitchCorrection.addEdgePointsToPitchContent(pitchPoints)
    local edgePointSpacing = 0.01

    local numPitchPoints = Lua.getTableLength(pitchPoints)

    if numPitchPoints < 1 then return end

    local pitchEnvelope = pitchPoints[1]:getEnvelope()
    local playrate = pitchPoints[1]:getPlayrate()

    local firstEdgePointTime = pitchPoints[1].time - edgePointSpacing
    reaper.InsertEnvelopePoint(pitchEnvelope, firstEdgePointTime * playrate, 0, 0, 0, false, true)
    local lastEdgePointTime = pitchPoints[numPitchPoints].time + edgePointSpacing
    reaper.InsertEnvelopePoint(pitchEnvelope, lastEdgePointTime * playrate, 0, 0, 0, false, true)
end

function PitchCorrection.correctTakePitchToPitchCorrections(take, pitchCorrections)
    if Lua.getTableLength(pitchCorrections) < 1 then return end

    local takeGUID = reaper.BR_GetMediaItemTakeGUID(take)
    local takePitchPoints = PitchPoint.getPitchPoints(takeGUID)
    local numTakePitchPoints = Lua.getTableLength(takePitchPoints)

    if numTakePitchPoints < 1 then return end

    local takePlayrate = takePitchPoints[1]:getPlayrate()
    local pitchEnvelope = takePitchPoints[1]:getEnvelope()

    for pointKey, point in PitchPoint.pairs(takePitchPoints) do
        local targetPitch = point.pitch
        local insideKeys = {}

        local numInsideKeys = 0
        for correctionKey, correction in PitchCorrection.pairs(pitchCorrections) do
            if correction:timeIsInside(point.time) then
                numInsideKeys = numInsideKeys + 1
                insideKeys[numInsideKeys] = correctionKey
            end
        end

        for index, key in ipairs(insideKeys) do
            local correction = pitchCorrections[key]

            if index == 1 then
                targetPitch = correction:getPitch(point.time)
            else
                local previousCorrection = pitchCorrections[insideKeys[index - 1]]
                local slideLength = previousCorrection.rightTime - correction.leftTime
                local pointTimeInCorrection = point.time - correction.leftTime
                local correctionWeight = pointTimeInCorrection / slideLength
                local correctionPitchDifference = correction:getPitch(point.time) - targetPitch

                targetPitch = targetPitch + correctionPitchDifference * correctionWeight
            end
        end

        --PitchCorrection.correctPitchAverage(point, averagePitch, targetPitch, averageCorrection)
        if numInsideKeys > 0 then
            PitchCorrection.correctPitchDrift(point, point.index, takePitchPoints, targetPitch, driftCorrection, driftCorrectionSpeed)
        end
        --PitchCorrection.correctPitchMod(point, targetPitch, modCorrection)
    end

    PitchCorrection.addPitchCorrectionsToEnvelope(pitchEnvelope, takePlayrate, takePitchPoints)
    PitchCorrection.addEdgePointsToPitchContent(takePitchPoints)

    reaper.Envelope_SortPointsEx(pitchEnvelope, -1)
end

return PitchCorrection