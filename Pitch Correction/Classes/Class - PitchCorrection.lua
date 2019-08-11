local PitchPoint = require "Classes.Class - PitchPoint"

-- Pitch correction settings:
local edgePointSpacing = 0.01
local averageCorrection = 0.0
local modCorrection = 0.0
local driftCorrection = 1.0
local driftCorrectionSpeed = 0.2
local zeroPointThreshold = 0.1



local function copyTable(source, base)
    if type(source) ~= "table" then return source end

    local meta = getmetatable(source)
    local new = base or {}
    for k, v in pairs(source) do
        if type(v) == "table" then
            if base then
                new[k] = GUI.table_copy(v, base[k])
            else
                new[k] = GUI.table_copy(v, nil)
            end

        else
            if not base or (base and new[k] == nil) then

                new[k] = v
            end
        end
    end
    setmetatable(new, meta)

    return new
end



------------------- Class -------------------
local PitchCorrection = {}

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

function PitchCorrection.getOverlapHandledPitchCorrections(pitchCorrections)
    local newCorrections = copyTable(pitchCorrections)

    local loopIndex = 1
    local oldKeys = {}

    -- Force overlap lengths to not be long enough to overlap multiple corrections.
    for key, correction in PitchCorrection.pairs(newCorrections) do
        if loopIndex > 2 then
            newCorrections[loopIndex - 2].rightTime = math.min(newCorrections[loopIndex - 2].rightTime, correction.leftTime)
        end
        oldKeys[loopIndex] = key
        loopIndex = loopIndex + 1
    end

    local previousCorrection = nil

    loopIndex = 1
    local previousKey = nil
    for key, correction in PitchCorrection.pairs(pitchCorrections) do
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

function PitchCorrection.correctPitchDrift(correctionPitchPoints, correction, correctionStrength, correctionSpeed)
    for pointKey, point in PitchPoint.pairs(correctionPitchPoints) do
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

        point.finalPitch = point.correctedPitch + pitchCorrection
    end
end

function PitchCorrection.addEdgePoints(pitchEnvelope, playrate, takePitchPoints, pitchCorrections)
    for key, correction in PitchCorrection.pairs(pitchCorrections) do
        local clearStart = playrate * correction.leftTime
        local clearEnd = playrate * correction.rightTime

        if not correction.overlaps then
            reaper.InsertEnvelopePoint(pitchEnvelope, correction.leftTime * playrate - edgePointSpacing, 0, 0, 0, false, true)
        end
        if not correction.isOverlapped then
            reaper.InsertEnvelopePoint(pitchEnvelope, correction.rightTime * playrate + edgePointSpacing, 0, 0, 0, false, true)
        end
    end

    -- Add edge points just before and after the beginning and end of pitch content.
    local firstEdgePointTime = takePitchPoints[1].time - edgePointSpacing
    reaper.InsertEnvelopePoint(pitchEnvelope, firstEdgePointTime * playrate, 0, 0, 0, false, true)
    local lastEdgePointTime = takePitchPoints[#takePitchPoints].time + edgePointSpacing
    reaper.InsertEnvelopePoint(pitchEnvelope, lastEdgePointTime * playrate, 0, 0, 0, false, true)
end

function PitchCorrection.addPitchCorrectionsToEnvelope(pitchEnvelope, playrate, takePitchPoints)
    local previousPoint = takePitchPoints[1]
    for key, point in PitchPoint.pairs(takePitchPoints) do
        local timePassedSinceLastPoint = point.time - previousPoint.time

        -- If a certain amount of time has passed since the last point, add zero value edge points in that space.
        if point.index > 1 and zeroPointThreshold then
            if timePassedSinceLastPoint >= zeroPointThreshold then
                local zeroPoint1Time = previousPoint.time + edgePointSpacing
                reaper.InsertEnvelopePoint(pitchEnvelope, zeroPoint1Time * playrate, 0, 0, 0, false, true)
                local zeroPoint2Time = point.time - edgePointSpacing
                reaper.InsertEnvelopePoint(pitchEnvelope, zeroPoint2Time * playrate, 0, 0, 0, false, true)
            end
        end

        -- Add envelope points with the correction value.
        reaper.InsertEnvelopePoint(pitchEnvelope, point.time * playrate, point.finalPitch - point.pitch, 0, 0, false, true)

        previousPoint = point
    end
end

function PitchCorrection.correctTakePitchToPitchCorrections(take, pitchCorrections)
    if #pitchCorrections < 1 then return end

    local takeGUID = reaper.BR_GetMediaItemTakeGUID(take)
    local takePitchPoints = PitchPoint.getPitchPoints(takeGUID)

    local takePlayrate = takePitchPoints[1]:getPlayrate()
    local pitchEnvelope = takePitchPoints[1]:getEnvelope()

    for correctionKey, correction in PitchCorrection.pairs(pitchCorrections) do
        local correctionPitchPoints = PitchPoint.getPitchPointsInTimeRange(takePitchPoints, correction.leftTime, correction.rightTime)
        local averagePitch = PitchPoint.getAveragePitch(correctionPitchPoints)

        --reaper.DeleteEnvelopePointRange(pitchEnvelope, correction.leftTime / takePlayrate, correction.rightTime / takePlayrate)

        for pointKey, point in PitchPoint.pairs(correctionPitchPoints) do
            local targetPitch = correction:getPitch(point.time)

            PitchCorrection.correctPitchAverage(point, averagePitch, targetPitch, averageCorrection)
            PitchCorrection.correctPitchMod(point, targetPitch, modCorrection)
        end

        PitchCorrection.correctPitchDrift(correctionPitchPoints, correction, driftCorrection, driftCorrectionSpeed)
    end

    PitchCorrection.addEdgePoints(pitchEnvelope, takePlayrate, takePitchPoints, pitchCorrections)
    PitchCorrection.addPitchCorrectionsToEnvelope(pitchEnvelope, takePlayrate, takePitchPoints)

    reaper.Envelope_SortPointsEx(pitchEnvelope, -1)
end

return PitchCorrection