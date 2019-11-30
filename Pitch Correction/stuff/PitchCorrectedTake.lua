local reaper = reaper
local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local TimeSeries = require("Pitch Correction.TimeSeries")
local TakeWithPitchPoints = require("Pitch Correction.TakeWithPitchPoints")

local defaultModCorrection = 0.0
local defaultDriftCorrection = 1.0
local defaultDriftTime = 0.12

local function lerp(x1, x2, ratio)
    return (1.0 - ratio) * x1 + ratio * x2
end
local function getLerpPitch(correction, nextCorrection, pitchPoint)
    local timeRatio = (pitchPoint.time - correction.time) / (nextCorrection.time - correction.time)
    return lerp(correction.pitch, nextCorrection.pitch, timeRatio)
end
local function getAveragePitch(correction, nextCorrection, index, group, timeRadius)
    local startingPoint = group[index]
    local pitchSum = startingPoint.pitch
    local numPoints = 1

    local currentPoint = startingPoint
    local smallestTimeToBoundary = math.min(math.abs(currentPoint.time - correction.time), math.abs(currentPoint.time - nextCorrection.time))
    local timeRadius = math.min(timeRadius, smallestTimeToBoundary)

    local i = index
    while true do
        i = i + 1
        currentPoint = group[i]
        if currentPoint == nil then break end

        if (currentPoint.time - startingPoint.time) >= timeRadius
        or currentPoint.time > nextCorrection.time then
            break
        end

        pitchSum = pitchSum + currentPoint.pitch
        numPoints = numPoints + 1
    end

    local i = index
    currentPoint = startingPoint
    while true do
        i = i - 1
        currentPoint = group[i]
        if currentPoint == nil then break end

        if (startingPoint.time - currentPoint.time) >= timeRadius
        or currentPoint.time < correction.time then
            break
        end

        pitchSum = pitchSum + currentPoint.pitch
        numPoints = numPoints + 1
    end

    return pitchSum / numPoints
end
local function getPitchCorrection(currentPitch, targetPitch, correctionStrength)
    return (targetPitch - currentPitch) * correctionStrength
end
local function getModCorrection(correction, nextCorrection, pitchPoint, currentCorrection)
    return getPitchCorrection(pitchPoint.pitch + currentCorrection,
                              getLerpPitch(correction, nextCorrection, pitchPoint),
                              correction.modCorrection)
end
local function getDriftCorrection(correction, nextCorrection, pitchIndex, pitchPoints)
    local pitchPoint = pitchPoints[pitchIndex]
    return getPitchCorrection(getAveragePitch(correction, nextCorrection, pitchIndex, pitchPoints, correction.driftTime * 0.5),
                              getLerpPitch(correction, nextCorrection, pitchPoint),
                              correction.driftCorrection)
end
local function clearEnvelopeUnderCorrection(correction, nextCorrection, envelope, playRate)
    reaper.DeleteEnvelopePointRange(envelope, correction.time * playRate, nextCorrection.time * playRate)
end
local function addZeroPointsToEnvelope(pitchIndex, pitchPoints, zeroPointThreshold, zeroPointSpacing, envelope, playRate)
    local point =         pitchPoints[pitchIndex]
    local previousPoint = pitchPoints[pitchIndex - 1]
    local nextPoint =     pitchPoints[pitchIndex + 1]

    local timeToPrevPoint = 0.0
    local timeToNextPoint = 0.0

    if previousPoint then
        timeToPrevPoint = point.time - previousPoint.time
    end

    if nextPoint then
        timeToNextPoint = nextPoint.time - point.time
    end

    if zeroPointThreshold then
        local scaledZeroPointThreshold = zeroPointThreshold / playRate

        if timeToPrevPoint >= scaledZeroPointThreshold or previousPoint == nil then
            local zeroPointTime = playRate * (point.time - zeroPointSpacing)
            reaper.DeleteEnvelopePointRange(envelope, zeroPointTime - zeroPointSpacing * 0.5, zeroPointTime + zeroPointSpacing * 0.5)
            reaper.InsertEnvelopePoint(envelope, zeroPointTime, 0, 0, 0, false, true)
        end

        if timeToNextPoint >= scaledZeroPointThreshold or nextPoint == nil then
            local zeroPointTime = playRate * (point.time + zeroPointSpacing)
            reaper.DeleteEnvelopePointRange(envelope, zeroPointTime - zeroPointSpacing * 0.5, zeroPointTime + zeroPointSpacing * 0.5)
            reaper.InsertEnvelopePoint(envelope, zeroPointTime, 0, 0, 0, false, true)
        end
    end
end
local function addEdgePointsToCorrection(correctionIndex, corrections, envelope, playRate)
    local correction =         corrections[correctionIndex]
    local previousCorrection = corrections[correctionIndex - 1]
    local nextCorrection =     corrections[correctionIndex + 1]
    local edgePointSpacing = 0.005

    if correction.isActive then
        if previousCorrection == nil or (previousCorrection and not previousCorrection.isActive) then
            reaper.InsertEnvelopePoint(envelope, (correction.time - edgePointSpacing) * playRate, 0.0, 0, 0, false, true)
        end
        if nextCorrection == nil then
            reaper.InsertEnvelopePoint(envelope, (correction.time + edgePointSpacing) * playRate, 0.0, 0, 0, false, true)
        end
    else
        reaper.InsertEnvelopePoint(envelope, (correction.time + edgePointSpacing) * playRate, 0.0, 0, 0, false, true)
    end
end
local function correctPitchPoints(correction, nextCorrection, pitchPoints, envelope, playRate)
    if nextCorrection then
        clearEnvelopeUnderCorrection(correction, nextCorrection, envelope, playRate)

        for i = 1, #pitchPoints do
            local pitchPoint = pitchPoints[i]
            if pitchPoint.time >= correction.time and pitchPoint.time <= nextCorrection.time then
                local driftCorrection = getDriftCorrection(correction, nextCorrection, i, pitchPoints)
                local modCorrection =   getModCorrection(correction, nextCorrection, pitchPoint, driftCorrection)
                reaper.InsertEnvelopePoint(envelope, pitchPoint.time * playRate, driftCorrection + modCorrection, 0, 0, false, true)
                addZeroPointsToEnvelope(i, pitchPoints, 0.2, 0.005, envelope, playRate)
            end
        end
    end
end

local PitchCorrectedTake = {}
function PitchCorrectedTake:new(object)
    local self = TakeWithPitchPoints:new(self)

    self.corrections = TimeSeries:new()

    function self:correctAllPitchPoints()
        self:clearPitchEnvelope()
        local corrections = self.corrections.points
        local pitchPoints = self.pitches.points
        local envelope = self.pitchEnvelope
        local playRate = self.playRate
        for i = 1, #corrections do
            local correction = corrections[i]
            local nextCorrection = corrections[i + 1]
            addEdgePointsToCorrection(i, corrections, envelope, playRate)
            if correction.isActive and nextCorrection then
                correctPitchPoints(correction, nextCorrection, pitchPoints, envelope, playRate)
            end
        end
        reaper.Envelope_SortPoints(envelope)
        reaper.UpdateArrange()
    end
    function self:insertPitchCorrectionPoint(point)
        point.sourceTime = self:getSourceTime(point.time)
        point.driftTime = point.driftTime or defaultDriftTime
        point.driftCorrection = point.driftCorrection or defaultDriftCorrection
        point.modCorrection = point.modCorrection or defaultModCorrection
        self.corrections.points[#self.corrections.points + 1] = point
    end

    if object then for k, v in pairs(object) do self[k] = v end end
    return self
end

return PitchCorrectedTake