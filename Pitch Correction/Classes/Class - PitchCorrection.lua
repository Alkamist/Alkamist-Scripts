package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Lua = require "Various Functions.Lua Functions"
local PitchPoint = require "Pitch Correction.Classes.Class - PitchPoint"



-- Pitch correction settings:
local averageCorrection = 0.0
local modCorrection = 0.2
local driftCorrection = 1.0
local driftCorrectionSpeed = 0.1
local zeroPointThreshold = 0.05
local zeroPointSpacing = 0.01
local edgePointSpacing = 0.01



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
function PitchCorrection.correctPitchMod(point, targetPitch, correctionStrength)
    local modDeviation = point.correctedPitch - targetPitch
    local pitchCorrection = -modDeviation * correctionStrength

    point.correctedPitch = point.correctedPitch + pitchCorrection
end

function PitchCorrection.correctPitchDrift(point, pointIndex, pitchPoints, correctionLeftTime, correctionRightTime, targetPitch, correctionStrength, correctionSpeed, pdSettings)
    local minTimePerPoint = pdSettings.windowStep / pdSettings.overlap
    local maxDriftPoints = math.ceil(correctionSpeed / minTimePerPoint)
    local numPitchPoints = Lua.getTableLength(pitchPoints)

    local driftAverage = 0
    local numDriftPoints = 0
    for i = 1, maxDriftPoints do
        local accessIndex = pointIndex + i - math.floor(maxDriftPoints * 0.5)

        if accessIndex >= 1 and accessIndex <= numPitchPoints then
            local driftPoint = pitchPoints[accessIndex]
            local correctionRadius = correctionSpeed * 0.5

            local driftPointIsInCorrectionRadius = driftPoint.time >= point.time - correctionRadius
                                               and driftPoint.time <= point.time + correctionRadius

            local driftPointIsInCorrectionTime = driftPoint.time >= correctionLeftTime
                                             and driftPoint.time <= correctionRightTime

            if driftPointIsInCorrectionRadius and driftPointIsInCorrectionTime then
                driftAverage = driftAverage + driftPoint.pitch

                numDriftPoints = numDriftPoints + 1
            end
        end
    end

    if numDriftPoints > 0 then
        driftAverage = driftAverage / numDriftPoints
    end

    local pitchDrift = driftAverage - targetPitch
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

        --reaper.GetEnvelopePointByTimeEx(pitchEnvelope, -1, point.time * playrate)
        -- Add envelope points with the correction value.
        reaper.InsertEnvelopePoint(pitchEnvelope, point.time * playrate, point.correctedPitch - point.pitch, 0, 0, false, true)

        previousPoint = point
    end
end

function PitchCorrection.addEdgePointsToPitchContent(pitchPoints)
    local numPitchPoints = Lua.getTableLength(pitchPoints)

    if numPitchPoints < 1 then return end

    local pitchEnvelope = pitchPoints[1]:getEnvelope()
    local playrate = pitchPoints[1]:getPlayrate()

    local firstEdgePointTime = pitchPoints[1].time - edgePointSpacing
    reaper.InsertEnvelopePoint(pitchEnvelope, firstEdgePointTime * playrate, 0, 0, 0, false, true)
    local lastEdgePointTime = pitchPoints[numPitchPoints].time + edgePointSpacing
    reaper.InsertEnvelopePoint(pitchEnvelope, lastEdgePointTime * playrate, 0, 0, 0, false, true)
end

function PitchCorrection.correctPitchPointsToPitchCorrections(pitchPoints, pitchCorrections, pdSettings)
    if Lua.getTableLength(pitchCorrections) < 1 then return end

    local numTakePitchPoints = Lua.getTableLength(pitchPoints)
    if numTakePitchPoints < 1 then return end

    local takePlayrate = pitchPoints[1]:getPlayrate()
    local pitchEnvelope = pitchPoints[1]:getEnvelope()

    for pointKey, point in PitchPoint.pairs(pitchPoints) do
        local targetPitch = point.pitch
        local insideKeys = {}

        local numInsideKeys = 0
        for correctionKey, correction in PitchCorrection.pairs(pitchCorrections) do
            reaper.DeleteEnvelopePointRange(pitchEnvelope, takePlayrate * correction.leftTime, takePlayrate * correction.rightTime)

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

        if numInsideKeys > 0 then
            local insideCorrectionLeft = pitchCorrections[insideKeys[1]].leftTime
            local insideCorrectionRight = pitchCorrections[insideKeys[numInsideKeys]].rightTime

            PitchCorrection.correctPitchDrift(point, point.index, pitchPoints, insideCorrectionLeft, insideCorrectionRight, targetPitch, driftCorrection, driftCorrectionSpeed, pdSettings)
        end

        PitchCorrection.correctPitchMod(point, targetPitch, modCorrection)
    end

    PitchCorrection.addPitchCorrectionsToEnvelope(pitchEnvelope, takePlayrate, pitchPoints)
    PitchCorrection.addEdgePointsToPitchContent(pitchPoints)

    reaper.Envelope_SortPointsEx(pitchEnvelope, -1)
end

return PitchCorrection