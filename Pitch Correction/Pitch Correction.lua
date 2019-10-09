local TimeSeries = require "TimeSeries"

local PitchCorrection = {}

local function lerp(x1, x2, ratio)
    return (1.0 - ratio) * x1 + ratio * x2
end

local function getLerpPitch(node, point)
    local timeRatio = (point.time - node.time) / (node.next.time - node.time)
    return lerp(node.pitch, node.next.pitch, timeRatio)
end

local function getAveragePitch(point, timeRadius)
    local startingPoint = point
    local currentPoint = point
    local pitchSum = point.pitch
    local numPoints = 1

    while true do
        if currentPoint == nil then break end
        currentPoint = point.next

        if (currentPoint.time - startingPoint.time) >= timeRadius then
            break
        end

        pitchSum = pitchSum + currentPoint.pitch
        numPoints = numPoints + 1
    end

    local currentPoint = point

    while true do
        if currentPoint == nil then break end
        currentPoint = point.prev

        if (startingPoint.time - currentPoint.time) >= timeRadius then
            break
        end

        pitchSum = pitchSum + currentPoint.pitch
        numPoints = numPoints + 1
    end

    local averagePitch = pitchSum / numPoints
end

local function getPitchCorrection(currentPitch, targetPitch, correctionStrength)
    return (targetPitch - currentPitch) * correctionStrength
end

local function getModCorrection(node, point, currentCorrection)
    return getPitchCorrection(point.pitch + currentCorrection,
                              getLerpPitch(node, point),
                              node.modCorrection)
end

local function getDriftCorrection(node, point)
    return getPitchCorrection(getAveragePitch(point, node.driftTime * 0.5),
                              getLerpPitch(node, point),
                              node.driftCorrection)
end

local function addZeroPointsToEnvelope(point, zeroPointThreshold, zeroPointSpacing)
    local timeToPrevPoint = 0.0
    local timeToNextPoint = 0.0

    if point.prev then
        timeToPrevPoint = point.time - point.prev.time
    end

    if point.next then
        timeToNextPoint = point.next.time - point.time
    end

    if zeroPointThreshold then
        local scaledZeroPointThreshold = zeroPointThreshold / point.playrate

        if timeToPrevPoint >= scaledZeroPointThreshold or point.prev == nil then
            local zeroPointTime = point.playrate * (point.time - zeroPointSpacing)
            reaper.DeleteEnvelopePointRange(point.envelope, zeroPointTime - zeroPointSpacing * 0.5, zeroPointTime + zeroPointSpacing * 0.5)
            reaper.InsertEnvelopePoint(point.envelope, zeroPointTime, 0, 0, 0, false, true)
        end

        if timeToNextPoint >= scaledZeroPointThreshold or point.next == nil then
            local zeroPointTime = point.playrate * (point.time + zeroPointSpacing)
            reaper.DeleteEnvelopePointRange(point.envelope, zeroPointTime - zeroPointSpacing * 0.5, zeroPointTime + zeroPointSpacing * 0.5)
            reaper.InsertEnvelopePoint(point.envelope, zeroPointTime, 0, 0, 0, false, true)
        end
    end
end

local function addEdgePointsToNode(node, envelope, playrate)
    if node.isActive then
        if node.prev then
            if not node.prev.isActive then
                reaper.InsertEnvelopePoint(envelope, (node.time + 0.00001) * playrate, 0.0, 0, 0, false, true)
            end
        else
            reaper.InsertEnvelopePoint(envelope, (node.time + 0.00001) * playrate, 0.0, 0, 0, false, true)
        end

        if not node.next.isActive then
            reaper.InsertEnvelopePoint(envelope, (node.next.time + 0.00001) * playrate, 0.0, 0, 0, false, true)
        end
    end
end

local function addPitchCorrectionToEnvelope(correction, envelope, playrate)
    reaper.InsertEnvelopePoint(envelope, point.time * playrate, correction, 0, 0, false, true)
end

local function clearEnvelopeUnderNode(node, envelope, playrate)
    reaper.DeleteEnvelopePointRange(envelope, node.time * playrate, node.next.time * playrate)
end

local function correctPoints(node, points)
    clearEnvelopeUnderNode(node, points[1].envelope, points[1].playrate)

    for _, point in ipairs(points) do
        local driftCorrection = getDriftCorrection(node, point)
        local finalCorrection = getModCorrection(node, point, driftCorrection)
        addPitchCorrectionToEnvelope(finalCorrection, point.envelope, point.playrate)
        addZeroPointsToEnvelope(point, node.zeroPointThreshold, node.zeroPointSpacing)
    end

    addEdgePointsToNode(node, points[1].envelope, points[1].playrate)
    reaper.Envelope_SortPoints(points[1].envelope)
end

local function getPointsInNode(node, points)
    return TimeSeries.getPointsInTimeRange({ leftTime = node.time, rightTime = node.next.time },
                                           points)
end

function PitchCorrection.correctPointsWithNodes(nodes, points)
    for _, node in ipairs(nodes) do
        if node.isActive then
            correctPoints( node, getPointsInNode(node, points) )
        end
    end
end

return PitchCorrection