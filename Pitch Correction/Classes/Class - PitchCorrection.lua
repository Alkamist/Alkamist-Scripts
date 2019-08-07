require "Scripts.Alkamist Scripts.Pitch Correction.Classes.Class - PitchPoint"

-- Pitch correction settings:
local edgePointSpacing = 0.01
local averageCorrection = 1.0
local modCorrection = 0.4
local driftCorrection = 1.0
local driftCorrectionSpeed = 0.17
local zeroPointThreshold = 0.1

------------------- Class -------------------
PitchCorrection = {}

function PitchCorrection:new(leftTime, rightTime, leftPitch, rightPitch)
    local object = {}

    object.leftTime = leftTime or 0
    object.rightTime = rightTime or 0
    object.leftPitch = leftPitch or 0
    object.rightPitch = rightPitch or 0

    object.overlaps = false
    object.isOverlapped = false

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
    if length ~= 0 then
        local timeRatio = (time - self.leftTime) / self:getLength()
        local rawPitch = self.leftPitch + self:getInterval() * timeRatio
        return rawPitch
    else
        return self.leftPitch
    end
end



------------------- Sorting -------------------
function pcPairs(pitchCorrections)
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

function getOverlapHandledPitchCorrections(pitchCorrections)
    local newCorrections = {table.unpack(pitchCorrections)}

    local loopIndex = 1
    local oldKeys = {}

    -- Force overlap lengths to not be long enough to overlap multiple corrections.
    for key, correction in pcPairs(newCorrections) do
        if loopIndex > 2 then
            newCorrections[loopIndex - 2].rightTime = math.min(newCorrections[loopIndex - 2].rightTime, correction.leftTime)
        end
        oldKeys[loopIndex] = key
        loopIndex = loopIndex + 1
    end

    local previousCorrection = nil

    loopIndex = 1
    local previousKey = nil
    for key, correction in pcPairs(pitchCorrections) do
        local newCorrection = newCorrections[key]

        if loopIndex > 1 then
            local overlapTime = previousCorrection.rightTime - newCorrection.leftTime

            if overlapTime > 0 then
                previousCorrection.rightPitch = previousCorrection:getPitch(previousCorrection.rightTime - overlapTime)
                previousCorrection.rightTime = previousCorrection.rightTime - overlapTime

                newCorrection.leftPitch = newCorrection:getPitch(newCorrection.leftTime + overlapTime)
                newCorrection.leftTime = newCorrection.leftTime + overlapTime

                local slideCorrection = PitchCorrection:new(previousCorrection.rightTime,
                                                            newCorrection.leftTime,
                                                            previousCorrection.rightPitch,
                                                            newCorrection.leftPitch)
                slideCorrection.overlaps = true
                slideCorrection.isOverlapped = true
                newCorrections["slide_" .. previousKey] = slideCorrection

                newCorrections[key].overlaps = true
                newCorrections[previousKey].isOverlapped = true
            else
                newCorrections[key].overlaps = false
                newCorrections[previousKey].isOverlapped = false
            end
        end

        previousKey = key
        previousCorrection = newCorrection
        loopIndex = loopIndex + 1
    end

    return newCorrections
end



------------------- Helpful Functions -------------------
function correctPitchAverage(point, averagePitch, targetPitch, correctionStrength)
    local averageDeviation = averagePitch - targetPitch
    local pitchCorrection = -averageDeviation * correctionStrength

    point.correctedPitch = point.correctedPitch + pitchCorrection
end

function correctPitchMod(point, targetPitch, correctionStrength)
    local modDeviation = point.correctedPitch - targetPitch
    local pitchCorrection = -modDeviation * correctionStrength

    point.correctedPitch = point.correctedPitch + pitchCorrection
end

function correctPitchDrift(correctionPitchPoints, correction, correctionStrength, correctionSpeed)
    for pointKey, point in ppPairs(correctionPitchPoints) do
        local targetPitch = correction:getPitch(point.time)

        local numDriftPoints = 1
        local driftIndex = 1
        local driftAverage = point.correctedPitch

        while pointKey - driftIndex >= 1 do
            local driftPoint = correctionPitchPoints[pointKey - driftIndex]

            if driftPoint.time >= point.time - correctionSpeed * 0.5 then
                driftAverage = driftAverage + driftPoint.correctedPitch
                numDriftPoints = numDriftPoints + 1
                driftIndex = driftIndex + 1
            else
                break
            end
        end

        driftIndex = 1
        while pointKey + driftIndex <= #correctionPitchPoints do
            local driftPoint = correctionPitchPoints[pointKey + driftIndex]

            if driftPoint.time <= point.time + correctionSpeed * 0.5 then
                driftAverage = driftAverage + driftPoint.correctedPitch
                numDriftPoints = numDriftPoints + 1
                driftIndex = driftIndex + 1
            else
                break
            end
        end

        driftAverage = driftAverage / numDriftPoints

        local pitchDrift = driftAverage - targetPitch
        local pitchCorrection = -pitchDrift * correctionStrength

        point.correctedPitch = point.correctedPitch + pitchCorrection
    end
end

function correctTakePitchToPitchCorrections(take, pitchCorrections)
    local takeGUID = reaper.BR_GetMediaItemTakeGUID(take)
    local takePitchPoints = getPitchPoints(takeGUID)

    local takePlayrate = takePitchPoints[1]:getPlayrate()
    local pitchEnvelope = takePitchPoints[1]:getEnvelope()

    --local startTime = reaper.time_precise()
    for correctionKey, correction in pcPairs(pitchCorrections) do
        local correctionPitchPoints = getPitchPointsInTimeRange(takePitchPoints, correction.leftTime, correction.rightTime)
        local averagePitch = getAveragePitch(correctionPitchPoints)

        for pointKey, point in ppPairs(correctionPitchPoints) do
            local targetPitch = correction:getPitch(point.time)

            correctPitchAverage(point, averagePitch, targetPitch, averageCorrection)
            correctPitchMod(point, targetPitch, modCorrection)
        end

        correctPitchDrift(correctionPitchPoints, correction, driftCorrection, driftCorrectionSpeed)
    end
    --msg(reaper.time_precise() - startTime)



    local previousPoint = takePitchPoints[1]
    for key, point in ppPairs(takePitchPoints) do
        local timePassedSinceLastPoint = point.time - previousPoint.time

        -- If a certain amount of time has passed since the last point, add zero value edge points in that space.
        if point.index > 1 and zeroPointThreshold then
            if timePassedSinceLastPoint >= zeroPointThreshold then
                local zeroPoint1Time = previousPoint.time + edgePointSpacing
                reaper.InsertEnvelopePoint(pitchEnvelope, zeroPoint1Time * takePlayrate, 0, 0, 0, false, true)
                local zeroPoint2Time = point.time - edgePointSpacing
                reaper.InsertEnvelopePoint(pitchEnvelope, zeroPoint2Time * takePlayrate, 0, 0, 0, false, true)
            end
        end

        -- Add envelope points with the correction value.
        reaper.InsertEnvelopePoint(pitchEnvelope, point.time * takePlayrate, point.correctedPitch - point.pitch, 0, 0, false, true)

        previousPoint = point
    end

    for key, correction in pcPairs(pitchCorrections) do
        local clearStart = takePlayrate * correction.leftTime
        local clearEnd = takePlayrate * correction.rightTime

        if not correction.overlaps then
            reaper.InsertEnvelopePoint(pitchEnvelope, correction.leftTime * takePlayrate - edgePointSpacing, 0, 0, 0, false, true)
        end
        if not correction.isOverlapped then
            reaper.InsertEnvelopePoint(pitchEnvelope, correction.rightTime * takePlayrate + edgePointSpacing, 0, 0, 0, false, true)
        end

        -- Add edge points just before and after the beginning and end of pitch content.
        local firstEdgePointTime = takePitchPoints[1].time - edgePointSpacing
        reaper.InsertEnvelopePoint(pitchEnvelope, firstEdgePointTime * takePlayrate, 0, 0, 0, false, true)
        local lastEdgePointTime = takePitchPoints[#takePitchPoints].time + edgePointSpacing
        reaper.InsertEnvelopePoint(pitchEnvelope, lastEdgePointTime * takePlayrate, 0, 0, 0, false, true)
    end

    reaper.Envelope_SortPointsEx(pitchEnvelope, -1)
end