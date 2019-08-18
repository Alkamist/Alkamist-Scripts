package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Lua = require "Various Functions.Lua Functions"
local PitchGroup = require "Pitch Correction.Classes.Class - PitchGroup"



-- Pitch correction settings:
local averageCorrection = 0.0
local modCorrection = 0.0
local driftCorrection = 1.0
local driftCorrectionSpeed = 0.17
local zeroPointThreshold = 0.05
local zeroPointSpacing = 0.01
local edgePointSpacing = 0.01



local PitchCorrection = {}

function PitchCorrection:new(o)
    o = o or {}

    o.nodes = {}

    setmetatable(o, self)
    self.__index = self

    return o
end



function PitchCorrection:getLength()
    return self:getRightNode().time - self:getLeftNode().time
end

function PitchCorrection:getInterval()
    return self:getRightNode().pitch - self:getLeftNode().pitch
end

function PitchCorrection:getPitch(time)
    local length = self:getLength()
    local leftNode = self:getLeftNode()
    local rightNode = self:getRightNode()

    if length > 0 then
        local timeRatio = (time - leftNode.time) / self:getLength()
        local rawPitch = leftNode.pitch + self:getInterval() * timeRatio
        return rawPitch

    elseif length < 0 then
        local timeRatio = (time - rightNode.time) / self:getLength()
        local rawPitch = rightNode.pitch + self:getInterval() * timeRatio
        return rawPitch

    else
        return leftNode.pitch
    end
end

function PitchCorrection:timeIsInside(time)
    return time >= self:getLeftNode().time and time <= self:getRightNode().time
end

function PitchCorrection.pairs(pitchCorrections)
    local temp = {}
    for key, correction in pairs(pitchCorrections) do
        table.insert(temp, {key, correction})
    end

    table.sort(temp, function(pc1, pc2)
        local pc1GoesFirst = pc1[2]:getLeftNode().time < pc2[2]:getLeftNode().time

        if pc1[2]:getLeftNode().time == pc2[2]:getLeftNode().time then
            pc1GoesFirst = pc1[2]:getRightNode().time > pc2[2]:getRightNode().time
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
function PitchCorrection.addZeroPointsToEnvelope(point, pointIndex, pitchPoints)
    if pointIndex <= 1 or pointIndex >= #pitchPoints then return end

    local prevPoint = pitchPoints[pointIndex - 1]
    local nextPoint = pitchPoints[pointIndex + 1]

    local timeToPrevPoint = point.time - prevPoint.time
    local timeToNextPoint = nextPoint.time - point.time

    if zeroPointThreshold then
        if timeToPrevPoint >= zeroPointThreshold then
            local zeroPointTime = playrate * (point.time - zeroPointSpacing)
            reaper.DeleteEnvelopePointRange(pitchEnvelope, zeroPointTime - zeroPointSpacing * 0.5, zeroPointTime + zeroPointSpacing * 0.5)
            reaper.InsertEnvelopePoint(pitchEnvelope, zeroPointTime, 0, 0, 0, false, true)
        end

        if timeToNextPoint >= zeroPointThreshold then
            local zeroPointTime = playrate * (point.time + zeroPointSpacing)
            reaper.DeleteEnvelopePointRange(pitchEnvelope, zeroPointTime - zeroPointSpacing * 0.5, zeroPointTime + zeroPointSpacing * 0.5)
            reaper.InsertEnvelopePoint(pitchEnvelope, zeroPointTime, 0, 0, 0, false, true)
        end
    end
end

function PitchCorrection.addEdgePointsToPitchContent(pitchPoints, pitchEnvelope, playrate)
    local numPitchPoints = #pitchPoints

    local firstEdgePointTime = playrate * (pitchPoints[1].time - edgePointSpacing)
    reaper.DeleteEnvelopePointRange(pitchEnvelope, firstEdgePointTime - edgePointSpacing * 0.5, firstEdgePointTime + edgePointSpacing * 0.5)
    reaper.InsertEnvelopePoint(pitchEnvelope, firstEdgePointTime, 0, 0, 0, false, true)

    local lastEdgePointTime = playrate * (pitchPoints[numPitchPoints].time + edgePointSpacing)
    reaper.DeleteEnvelopePointRange(pitchEnvelope, lastEdgePointTime - edgePointSpacing * 0.5, lastEdgePointTime + edgePointSpacing * 0.5)
    reaper.InsertEnvelopePoint(pitchEnvelope, lastEdgePointTime, 0, 0, 0, false, true)
end

function PitchCorrection.addEdgePointsToGroupOfCorrections(corrections, pitchEnvelope, playrate)
    local numCorrections = Lua.getTableLength(corrections)

    if numCorrections < 1 then return end

    local leftEdgeTime = nil
    local rightEdgeTime = nil

    for correctionKey, correction in PitchCorrection.pairs(corrections) do
        if leftEdgeTime == nil then leftEdgeTime = correction:getLeftNode().time end
        if rightEdgeTime == nil then rightEdgeTime = correction:getRightNode().time end

        if correction:getLeftNode().time < leftEdgeTime then
            leftEdgeTime = correction:getLeftNode().time
        end

        if correction:getRightNode().time > rightEdgeTime then
            rightEdgeTime = correction:getRightNode().time
        end
    end

    leftEdgeTime = playrate * leftEdgeTime
    reaper.DeleteEnvelopePointRange(pitchEnvelope, leftEdgeTime - edgePointSpacing * 0.5, leftEdgeTime + edgePointSpacing * 0.5)
    reaper.InsertEnvelopePoint(pitchEnvelope, leftEdgeTime, 0, 0, 0, false, true)

    rightEdgeTime = playrate * rightEdgeTime
    reaper.DeleteEnvelopePointRange(pitchEnvelope, rightEdgeTime - edgePointSpacing * 0.5, rightEdgeTime + edgePointSpacing * 0.5)
    reaper.InsertEnvelopePoint(pitchEnvelope, rightEdgeTime, 0, 0, 0, false, true)
end

function PitchCorrection.getPointsInCorrections(pitchGroup, pitchCorrections)
    local pointsInCorrections = {}

    local pointIndexes = {}
    for correctionKey, correction in PitchCorrection.pairs(pitchCorrections) do
        local leftPoint, leftPointIndex = PitchGroup.findPointByTime(correction:getLeftNode().time, pitchPoints, false)
        local rightPoint, rightPointIndex = PitchGroup.findPointByTime(correction:getRightNode().time, pitchPoints, true)

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

function PitchCorrection.applyCorrectionsToPitchGroup(pitchGroup, pitchCorrections, pdSettings)
    local pointsInCorrections = PitchCorrection.getPointsInCorrections(pitchGroup, pitchCorrections)

    local pitchEnvelope = pitchGroup.envelope
    local playrate = pitchGroup.playrate

    for correctionKey, correction in PitchCorrection.pairs(pitchCorrections) do
        reaper.DeleteEnvelopePointRange(pitchEnvelope, playrate * correction:getLeftNode().time, playrate * correction:getRightNode().time)
    end

    local previousPoint = pointsInCorrections[1]
    for pointIndex, point in ipairs(pointsInCorrections) do
        point.correctedPitch = point.pitch
        local targetPitch = point.pitch
        local insideKeys = {}
        local numInsideKeys = 0

        for correctionKey, correction in PitchCorrection.pairs(pitchCorrections) do
            if correction:timeIsInside(point.time) then
                numInsideKeys = numInsideKeys + 1
                insideKeys[numInsideKeys] = correctionKey
            end

            correction.alreadyCorrected = true
        end

        for index, key in ipairs(insideKeys) do
            local correction = pitchCorrections[key]

            if index == 1 then
                targetPitch = correction:getPitch(point.time)
            else
                local previousCorrection = pitchCorrections[insideKeys[index - 1]]
                local slideLength = previousCorrection:getRightNode().time - correction:getLeftNode().time
                local pointTimeInCorrection = point.time - correction:getLeftNode().time
                local correctionWeight = pointTimeInCorrection / slideLength
                local correctionPitchDifference = correction:getPitch(point.time) - targetPitch

                targetPitch = targetPitch + correctionPitchDifference * correctionWeight
            end
        end

        if numInsideKeys > 0 then
            local insideCorrectionLeft = pitchCorrections[insideKeys[1]]:getLeftNode().time
            local insideCorrectionRight = pitchCorrections[insideKeys[numInsideKeys]]:getRightNode().time

            PitchCorrection.correctPitchDrift(point, pointIndex, pointsInCorrections, insideCorrectionLeft, insideCorrectionRight, targetPitch, driftCorrection, driftCorrectionSpeed, pdSettings)
        end

        PitchCorrection.correctPitchMod(point, targetPitch, modCorrection)

        reaper.InsertEnvelopePoint(pitchEnvelope, point.time * playrate, point.correctedPitch - point.pitch, 0, 0, false, true)
        --PitchCorrection.addZeroPointsToEnvelope(point, point.index, pitchPoints)

        previousPoint = point
    end

    PitchCorrection.addEdgePointsToPitchContent(pitchGroup.points, pitchEnvelope, playrate)
    reaper.Envelope_SortPoints(pitchEnvelope)
end

function PitchCorrection:getOverlappingCorrections()
    local overlappingCorrections = {}

    table.insert(overlappingCorrections, self)

    local currCorrection = self

    -- Insert left overlapping corrections into the group.
    if self.prevCorrection then
        repeat
            local prevCorrectionOverlaps = currCorrection.prevCorrection:getRightNode().time > currCorrection:getLeftNode().time

            if prevCorrectionOverlaps then table.insert(overlappingCorrections, currCorrection.prevCorrection) end

            currCorrection = currCorrection.prevCorrection
        until not prevCorrectionOverlaps or currCorrection.prevCorrection == nil
    end

    currCorrection = self

    -- Insert right overlapping corrections into the group.
    if self.nextCorrection then
        repeat
            local nextCorrectionOverlaps = currCorrection.nextCorrection:getLeftNode().time < currCorrection:getRightNode().time

            if nextCorrectionOverlaps then table.insert(overlappingCorrections, currCorrection.nextCorrection) end

            currCorrection = currCorrection.nextCorrection
        until not nextCorrectionOverlaps or currCorrection.nextCorrection == nil
    end

    return overlappingCorrections
end

function PitchCorrection:correctPitchGroups(pitchGroups, pdSettings)
    if #pitchGroups < 1 then return end

    for groupIndex, group in ipairs(pitchGroups) do

        local overlappingCorrections = self:getOverlappingCorrections()

        --PitchCorrection.addEdgePointsToGroupOfCorrections(overlappingCorrections, pitchEnvelope, playrate)
        PitchCorrection.applyCorrectionsToPitchGroup(group, overlappingCorrections, pdSettings)

    end
end

return PitchCorrection