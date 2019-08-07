require "Scripts.Alkamist Scripts.Pitch Correction.Classes.Class - PitchPoint"

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
function correctPitchAverage(takePitchPoints, pitchCorrections, correctionStrength)
    for correctionKey, correction in pcPairs(pitchCorrections) do
        local previousPoint = takePitchPoints[1]

        local pitchPoints = getPitchPointsInTimeRange(takePitchPoints, correction.leftTime, correction.rightTime)
        local averagePitch = getAveragePitch(pitchPoints)
        for pointKey, point in ppPairs(pitchPoints) do
            local timePassedSinceLastPoint = point.time - previousPoint.time

            local targetNote = correction:getPitch(point.time)

            local averageDeviation = averagePitch - targetNote
            local pitchCorrection = -averageDeviation * correctionStrength

            point.correctedPitch = point.correctedPitch + pitchCorrection

            previousPoint = point
        end
    end
end

function correctPitchMod(takePitchPoints, pitchCorrections, correctionStrength)
    for correctionKey, correction in pcPairs(pitchCorrections) do
        local previousPoint = takePitchPoints[1]

        local pitchPoints = getPitchPointsInTimeRange(takePitchPoints, correction.leftTime, correction.rightTime)
        for pointKey, point in ppPairs(pitchPoints) do
            local timePassedSinceLastPoint = point.time - previousPoint.time

            local targetNote = correction:getPitch(point.time)

            local modDeviation = point.correctedPitch - targetNote
            local pitchCorrection = -modDeviation * correctionStrength

            point.correctedPitch = point.correctedPitch + pitchCorrection

            previousPoint = point
        end
    end
end

--[[function correctPitchDrift(takePitchPoints, pitchCorrections, correctionStrength, correctionSpeed)
    for correctionKey, correction in pcPairs(pitchCorrections) do
        local previousPoint = takePitchPoints[1]

        local pitchPoints = getPitchPointsInTimeRange(takePitchPoints, correction.leftTime, correction.rightTime)
        for pointKey, point in ppPairs(pitchPoints) do
            local timePassedSinceLastPoint = point.time - previousPoint.time

            local targetNote = correction:getPitch(point.time)



            -- Apply the pitch drift to the pitch correction.
            local scaledPitchDrift = pitchDrift * driftCorrection
            pitchCorrection = pitchCorrection - scaledPitchDrift







            previousPoint = point
        end
    end
end]]--