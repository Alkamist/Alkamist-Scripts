package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Lua = require "Various Functions.Lua Functions"
local PitchPoint = require "Pitch Correction.Classes.Class - PitchPoint"



-- Pitch correction settings:
local averageCorrection = 0.0
local modCorrection = 1.0
local driftCorrection = 0.0
local driftCorrectionSpeed = 0.1
local zeroPointThreshold = 0.05
local zeroPointSpacing = 0.01
local edgePointSpacing = 0.01



------------------- Class -------------------
local PitchCorrection = {}

function PitchCorrection:new(leftTime, rightTime, leftPitch, rightPitch, prevCorrection, nextCorrection)
    local object = {}

    object.leftTime = leftTime or 0
    object.rightTime = rightTime or 0
    object.leftPitch = leftPitch or 0
    object.rightPitch = rightPitch or 0

    object.prevCorrection = object.prevCorrection or prevCorrection
    object.nextCorrection = object.nextCorrection or nextCorrection

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

function PitchCorrection.updateLinkedOrder(pitchCorrections)
    local numPitchCorrections = Lua.getTableLength(pitchCorrections)
    local prevCorrection = nil

    local numLoops = 0
    for correctionKey, correction in PitchCorrection.pairs(pitchCorrections) do
        numLoops = numLoops + 1

        correction.prevCorrection = prevCorrection

        if numLoops > 1 then
            prevCorrection.nextCorrection = correction
        end

        if numLoops == numPitchCorrections then
            correction.nextCorrection = nil
        end

        prevCorrection = correction
    end
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

-- If a certain amount of time has passed since the last point, add zero value edge points in that space.
function PitchCorrection.addZeroPointToEnvelope(point, previousPoint)
    local timePassedSinceLastPoint = point.time - previousPoint.time

    local pitchEnvelope = point:getEnvelope()
    local playrate = point:getPlayrate()

    if point.index > 1 and zeroPointThreshold then
        if timePassedSinceLastPoint >= zeroPointThreshold then
            local zeroPoint1Time = previousPoint.time + zeroPointSpacing
            reaper.InsertEnvelopePoint(pitchEnvelope, zeroPoint1Time * playrate, 0, 0, 0, false, true)
            local zeroPoint2Time = point.time - zeroPointSpacing
            reaper.InsertEnvelopePoint(pitchEnvelope, zeroPoint2Time * playrate, 0, 0, 0, false, true)
        end
    end
end

function PitchCorrection.addCorrectedPointToEnvelope(point)
    local pitchEnvelope = point:getEnvelope()
    local playrate = point:getPlayrate()

    reaper.InsertEnvelopePoint(pitchEnvelope, point.time * playrate, point.correctedPitch - point.pitch, 0, 0, false, true)
end

function PitchCorrection.addEdgePointsToPitchContent(pitchPoints)
    local numPitchPoints = #pitchPoints

    if numPitchPoints < 1 then return end
    local pitchEnvelope = pitchPoints[1]:getEnvelope()
    local playrate = pitchPoints[1]:getPlayrate()

    local firstEdgePointTime = playrate * (pitchPoints[1].time - edgePointSpacing)
    reaper.DeleteEnvelopePointRange(pitchEnvelope, firstEdgePointTime - edgePointSpacing * 0.5, firstEdgePointTime + edgePointSpacing * 0.5)
    reaper.InsertEnvelopePoint(pitchEnvelope, firstEdgePointTime, 0, 0, 0, false, true)

    local lastEdgePointTime = playrate * (pitchPoints[numPitchPoints].time + edgePointSpacing)
    reaper.DeleteEnvelopePointRange(pitchEnvelope, lastEdgePointTime - edgePointSpacing * 0.5, lastEdgePointTime + edgePointSpacing * 0.5)
    reaper.InsertEnvelopePoint(pitchEnvelope, lastEdgePointTime, 0, 0, 0, false, true)
end

function PitchCorrection.getPointsInCorrections(pitchPoints, pitchCorrections)
    local pointsInCorrections = {}

    local pointIndexes = {}
    for correctionKey, correction in PitchCorrection.pairs(pitchCorrections) do
        local leftPoint, leftPointIndex = PitchPoint.findPointByTime(correction.leftTime, pitchPoints, false)
        local rightPoint, rightPointIndex = PitchPoint.findPointByTime(correction.rightTime, pitchPoints, true)

        table.insert(pointIndexes, leftPointIndex)
        table.insert(pointIndexes, rightPointIndex)
    end

    local lowestIndex = #pitchPoints
    local highestIndex = 1
    for key, value in ipairs(pointIndexes) do
        if value < lowestIndex then lowestIndex = value end
        if value > highestIndex then highestIndex = value end
    end

    for i = lowestIndex, highestIndex do
        table.insert(pointsInCorrections, pitchPoints[i])
    end

    return pointsInCorrections
end

function PitchCorrection.applyCorrectionsToPitchPoints(pitchPoints, pitchCorrections, pdSettings)
    if #pitchPoints < 1 then return end

    local pointsInCorrections = PitchCorrection.getPointsInCorrections(pitchPoints, pitchCorrections)

    local pitchEnvelope = pitchPoints[1]:getEnvelope()
    local playrate = pitchPoints[1]:getPlayrate()

    for correctionKey, correction in PitchCorrection.pairs(pitchCorrections) do
        reaper.DeleteEnvelopePointRange(pitchEnvelope, playrate * correction.leftTime, playrate * correction.rightTime)
    end

    local previousPoint = pointsInCorrections[1]
    for pointKey, point in PitchPoint.pairs(pointsInCorrections) do
        local targetPitch = point.pitch
        local insideKeys = {}
        local numInsideKeys = 0

        local playrate = point:getPlayrate()
        local pitchEnvelope = point:getEnvelope()

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

        if numInsideKeys > 0 then
            local insideCorrectionLeft = pitchCorrections[insideKeys[1]].leftTime
            local insideCorrectionRight = pitchCorrections[insideKeys[numInsideKeys]].rightTime

            --PitchCorrection.correctPitchDrift(point, point.index, pointsInCorrections, insideCorrectionLeft, insideCorrectionRight, targetPitch, driftCorrection, driftCorrectionSpeed, pdSettings)
        end

        PitchCorrection.correctPitchMod(point, targetPitch, modCorrection)

        PitchCorrection.addCorrectedPointToEnvelope(point)
        --PitchCorrection.addZeroPointToEnvelope(point, previousPoint)

        previousPoint = point
    end

    PitchCorrection.addEdgePointsToPitchContent(pitchPoints)
    reaper.Envelope_SortPoints(pitchEnvelope)
end

function PitchCorrection.getOverlappingCorrections(correction)
    local overlappingCorrections = {}

    table.insert(overlappingCorrections, correction)

    local currCorrection = correction

    -- Insert left overlapping corrections into the group.
    if correction.prevCorrection then
        repeat
            local prevCorrectionOverlaps = currCorrection.prevCorrection.rightTime > currCorrection.leftTime

            if prevCorrectionOverlaps then table.insert(overlappingCorrections, currCorrection.prevCorrection) end

            currCorrection = currCorrection.prevCorrection
        until not prevCorrectionOverlaps or currCorrection.prevCorrection == nil
    end

    currCorrection = correction

    -- Insert right overlapping corrections into the group.
    if correction.nextCorrection then
        repeat
            local nextCorrectionOverlaps = currCorrection.nextCorrection.leftTime < currCorrection.rightTime

            if nextCorrectionOverlaps then table.insert(overlappingCorrections, currCorrection.nextCorrection) end

            currCorrection = currCorrection.nextCorrection
        until not nextCorrectionOverlaps or currCorrection.nextCorrection == nil
    end

    return overlappingCorrections
end

function PitchCorrection.correctPitchPoints(pitchPoints, correction, pdSettings)
    if #pitchPoints < 1 then return end
    if correction == nil then return end

    local overlappingCorrections = PitchCorrection.getOverlappingCorrections(correction)

    PitchCorrection.applyCorrectionsToPitchPoints(pitchPoints, overlappingCorrections, pdSettings)
end

return PitchCorrection