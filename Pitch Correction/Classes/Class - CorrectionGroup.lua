package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Lua = require "Various Functions.Lua Functions"
local PitchGroup = require "Pitch Correction.Classes.Class - PitchGroup"



-- Pitch correction settings:
local averageCorrection = 0.0
local modCorrection = 1.0
local driftCorrection = 1.0
local driftCorrectionSpeed = 0.17
local zeroPointThreshold = 0.05
local zeroPointSpacing = 0.01
local edgePointSpacing = 0.01



local CorrectionGroup = {}

function CorrectionGroup:new(o)
    o = o or {}

    o.nodes = o.nodes or {}

    setmetatable(o, self)
    self.__index = self

    return o
end

function CorrectionGroup:sort()
    table.sort(self.nodes, function(a, b) return a.time < b.time end)
end

function CorrectionGroup:addNode(newNode)
    table.insert(self.nodes, newNode)
    self:sort()

    return newNode
end

function CorrectionGroup:getNodeIndex(inputNode)
    for index, node in ipairs(self.nodes) do
        if inputNode == node then
            return index
        end
    end

    return nil
end

function CorrectionGroup:getBindingNodes(time)
    local previousNode = nil

    for index, node in ipairs(self.nodes) do

        previousNode = previousNode or node

        if node.time >= time and previousNode.time <= time then
            return previousNode, node
        end

        if index == #self.nodes and node.time <= time then
            return node, nil
        end

        previousNode = node

    end

    return nil, nil
end

function CorrectionGroup:getPitch(time, leftNode, rightNode)
    if not leftNode or not rightNode then
        leftNode, rightNode = self:getBindingNodes(time)
    end

    local timeRatio = (time - leftNode.time) / (rightNode.time - leftNode.time)
    local pitch = leftNode.pitch + (rightNode.pitch - leftNode.pitch) * timeRatio

    return pitch
end

function CorrectionGroup:timeIsInActiveCorrection(time, leftNode, rightNode)
    if not leftNode or not rightNode then
        leftNode, rightNode = self:getBindingNodes(time)
    end

    if leftNode and rightNode then
        return leftNode.isActive
    end

    return false
end

function CorrectionGroup:correctPitchDrift(point, pointIndex, pitchGroup, editOffset, leftNode, rightNode, correctionStrength, correctionSpeed, pdSettings)
    local minTimePerPoint = pdSettings.windowStep / pdSettings.overlap
    local maxDriftPoints = math.ceil(correctionSpeed / minTimePerPoint)
    local numPitchPoints = #pitchGroup.points

    local correctionLeftTime = leftNode.time
    local correctionRightTime = rightNode.time

    local driftAverage = 0
    local numDriftPoints = 0
    for i = 1, maxDriftPoints do
        local accessIndex = pointIndex + i - math.ceil(maxDriftPoints * 0.5)

        if accessIndex >= 1 and accessIndex <= numPitchPoints then
            local driftPoint = pitchGroup.points[accessIndex]
            local relativePointTime = driftPoint.time - pitchGroup.startOffset
            local correctionRadius = correctionSpeed * 0.5

            local driftPointIsInCorrectionRadius = driftPoint.time >= point.time - correctionRadius
                                               and driftPoint.time <= point.time + correctionRadius

            local driftPointIsInCorrectionTime = relativePointTime >= correctionLeftTime
                                             and relativePointTime <= correctionRightTime

            if driftPointIsInCorrectionRadius and driftPointIsInCorrectionTime then
                local targetPitch = self:getPitch(relativePointTime + editOffset, leftNode, rightNode)
                driftAverage = driftAverage + driftPoint.pitch - targetPitch

                numDriftPoints = numDriftPoints + 1
            end
        end
    end

    if numDriftPoints > 0 then
        driftAverage = driftAverage / numDriftPoints
    end

    local pitchCorrection = -driftAverage * correctionStrength

    point.correctedPitch = point.correctedPitch + pitchCorrection
end

function CorrectionGroup.correctPitchMod(point, targetPitch, correctionStrength)
    local modDeviation = point.correctedPitch - targetPitch

    local pitchCorrection = -modDeviation * correctionStrength

    point.correctedPitch = point.correctedPitch + pitchCorrection
end

--[[function CorrectionGroup.correctPitchMod(point, targetPitch, correctionStrength)
    local modDeviation = point.correctedPitch - targetPitch
    local pitchCorrection = -modDeviation * correctionStrength

    point.correctedPitch = point.correctedPitch + pitchCorrection
end]]--

function CorrectionGroup:addZeroPointsToEnvelope(point, pointIndex, pitchGroup)
    local pointTime = point.time - pitchGroup.startOffset
    local prevPointTime = 0.0
    local timeToPrevPoint = 0.0

    if pointIndex > 1 then
        prevPointTime = pitchGroup.points[pointIndex - 1].time - pitchGroup.startOffset
        timeToPrevPoint = pointTime - prevPointTime
    end

    if zeroPointThreshold then
        if timeToPrevPoint >= zeroPointThreshold then
            local zeroPoint1Time = pitchGroup.playrate * (pointTime - zeroPointSpacing)
            reaper.DeleteEnvelopePointRange(pitchGroup.envelope, zeroPoint1Time - zeroPointSpacing * 0.5, zeroPoint1Time + zeroPointSpacing * 0.5)
            reaper.InsertEnvelopePoint(pitchGroup.envelope, zeroPoint1Time, 0, 0, 0, false, true)

            local zeroPoint2Time = pitchGroup.playrate * (prevPointTime + zeroPointSpacing)
            reaper.DeleteEnvelopePointRange(pitchGroup.envelope, zeroPoint2Time - zeroPointSpacing * 0.5, zeroPoint2Time + zeroPointSpacing * 0.5)
            reaper.InsertEnvelopePoint(pitchGroup.envelope, zeroPoint2Time, 0, 0, 0, false, true)
        end
    end
end

function CorrectionGroup:addEdgePointsToCorrectionGroup(pitchGroup)
    local leftEdgeTime = pitchGroup.playrate * (self.nodes[1].time - pitchGroup.editOffset)
    local rightEdgeTime = pitchGroup.playrate * (self.nodes[#self.nodes].time - pitchGroup.editOffset)

    reaper.InsertEnvelopePoint(pitchGroup.envelope, leftEdgeTime, 0, 0, 0, false, true)
    reaper.InsertEnvelopePoint(pitchGroup.envelope, rightEdgeTime, 0, 0, 0, false, true)
end

function CorrectionGroup.addEdgePointsToPitchContent(pitchGroup)
    local leftEdgeTime = pitchGroup.playrate * (pitchGroup.points[1].time - pitchGroup.startOffset - edgePointSpacing * 0.5)
    local rightEdgeTime = pitchGroup.playrate * (pitchGroup.points[#pitchGroup.points].time - pitchGroup.startOffset + edgePointSpacing * 0.5)

    local scaledEdgepointSpacing = edgePointSpacing * 0.5 * pitchGroup.playrate

    reaper.DeleteEnvelopePointRange(pitchGroup.envelope, leftEdgeTime - scaledEdgepointSpacing, leftEdgeTime + scaledEdgepointSpacing)
    reaper.DeleteEnvelopePointRange(pitchGroup.envelope, rightEdgeTime - scaledEdgepointSpacing, rightEdgeTime + scaledEdgepointSpacing)

    reaper.InsertEnvelopePoint(pitchGroup.envelope, leftEdgeTime, 0, 0, 0, false, true)
    reaper.InsertEnvelopePoint(pitchGroup.envelope, rightEdgeTime, 0, 0, 0, false, true)
end

function CorrectionGroup:addEdgePointsToNodes(pitchGroup)
    local prevNode = nil

    for index, node in ipairs(self.nodes) do
        prevNode = prevNode or node

        if not node.isActive then
            reaper.InsertEnvelopePoint(pitchGroup.envelope, (node.time + edgePointSpacing * 0.5) * pitchGroup.playrate, 0.0, 0, 0, false, true)

        elseif not prevNode.isActive then
            reaper.InsertEnvelopePoint(pitchGroup.envelope, (node.time - edgePointSpacing * 0.5) * pitchGroup.playrate, 0.0, 0, 0, false, true)
        end

        prevNode = node
    end
end

function CorrectionGroup:correctPitchGroup(pitchGroup)
    if #self.nodes < 2 then return end

    --local prevRelativePointTime = nil
    for pointIndex, point in ipairs(pitchGroup.points) do

        --self:correctPitchDrift(point, pointIndex, pitchGroup)
        --self:correctPitchMod(point, pointIndex, pitchGroup)

        --self:insertCorrectedPointToEnvelope(pitchGroup)

        self:addZeroPointsToEnvelope(point, pointIndex, pitchGroup)


        --[[local relativePointTime = point.time - pitchGroup.startOffset
        prevRelativePointTime = prevRelativePointTime or relativePointTime

        local leftNode, rightNode = self:getBindingNodes(relativePointTime + pitchGroup.editOffset)

        if self:timeIsInActiveCorrection(relativePointTime + pitchGroup.editOffset, leftNode, rightNode) then
            point.correctedPitch = point.pitch
            local targetPitch = self:getPitch(relativePointTime + pitchGroup.editOffset, leftNode, rightNode)

            --self:correctPitchDrift(point, pointIndex, pitchGroup, pitchGroup.editOffset, leftNode, rightNode, driftCorrection, driftCorrectionSpeed, pdSettings)
            CorrectionGroup.correctPitchMod(point, targetPitch, modCorrection)

            reaper.InsertEnvelopePoint(pitchGroup.envelope, relativePointTime * pitchGroup.playrate, point.correctedPitch - point.pitch, 0, 0, false, true)
        end]]--

        --self:addZeroPointsToEnvelope(relativePointTime, prevRelativePointTime, pitchGroup.envelope, pitchGroup.playrate)

        --prevRelativePointTime = relativePointTime
    end

    self:addEdgePointsToNodes(pitchGroup)
    self:addEdgePointsToCorrectionGroup(pitchGroup)
    CorrectionGroup.addEdgePointsToPitchContent(pitchGroup)

    reaper.Envelope_SortPoints(pitchGroup.envelope)
end

return CorrectionGroup