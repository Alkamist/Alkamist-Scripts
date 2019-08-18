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

function CorrectionGroup:test(pitchGroup, pdSettings)
    msg(self.nodes)
end

function CorrectionGroup:addNode(newNode)
    table.insert(self.nodes, newNode)
    self:sort()

    return newNode
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

function CorrectionGroup:getPitch(time)
    local leftNode, rightNode = self:getBindingNodes(time)

    local timeRatio = (time - leftNode.time) / (rightNode.time - leftNode.time)
    local pitch = leftNode.pitch + (rightNode.pitch - leftNode.pitch) * timeRatio

    return pitch
end

function CorrectionGroup:timeIsInActiveCorrection(time)
    local leftNode, rightNode = self:getBindingNodes(time)

    if leftNode and rightNode then
        return leftNode.isActive
    end

    return false
end

function CorrectionGroup.correctPitchMod(point, targetPitch, correctionStrength)
    local modDeviation = point.correctedPitch - targetPitch
    local pitchCorrection = -modDeviation * correctionStrength

    point.correctedPitch = point.correctedPitch + pitchCorrection
end

function CorrectionGroup:addZeroPointsToEnvelope(pointTime, prevPointTime, pitchEnvelope, playrate)
    local timeToPrevPoint = pointTime - prevPointTime

    if zeroPointThreshold then
        if timeToPrevPoint >= zeroPointThreshold then
            local zeroPoint1Time = playrate * (pointTime - zeroPointSpacing)
            reaper.DeleteEnvelopePointRange(pitchEnvelope, zeroPoint1Time - zeroPointSpacing * 0.5, zeroPoint1Time + zeroPointSpacing * 0.5)
            reaper.InsertEnvelopePoint(pitchEnvelope, zeroPoint1Time, 0, 0, 0, false, true)

            local zeroPoint2Time = playrate * (prevPointTime + zeroPointSpacing)
            reaper.DeleteEnvelopePointRange(pitchEnvelope, zeroPoint2Time - zeroPointSpacing * 0.5, zeroPoint2Time + zeroPointSpacing * 0.5)
            reaper.InsertEnvelopePoint(pitchEnvelope, zeroPoint2Time, 0, 0, 0, false, true)
        end
    end
end

function CorrectionGroup:clearEnvelopeContent(pitchGroup, editOffset)
    if #self.nodes < 2 then return end

    local pitchEnvelope = pitchGroup.envelope
    local playrate = pitchGroup.playrate

    local leftEdgeTime = playrate * (self.nodes[1].time - editOffset - edgePointSpacing * 0.5)
    local rightEdgeTime = playrate * (self.nodes[#self.nodes].time - editOffset + edgePointSpacing * 0.5)

    reaper.DeleteEnvelopePointRange(pitchEnvelope, leftEdgeTime, rightEdgeTime)
end

function CorrectionGroup.addEdgePoints(pitchEnvelope, playrate, leftEdgeTime, rightEdgeTime)
    reaper.InsertEnvelopePoint(pitchEnvelope, leftEdgeTime, 0, 0, 0, false, true)
    reaper.InsertEnvelopePoint(pitchEnvelope, rightEdgeTime, 0, 0, 0, false, true)
end

function CorrectionGroup.addEdgePointsToPitchContent(pitchGroup, pitchEnvelope, playrate)
    local leftEdgeTime = playrate * (pitchGroup.points[1].time - pitchGroup.startOffset - edgePointSpacing * 0.5)
    local rightEdgeTime = playrate * (pitchGroup.points[#pitchGroup.points].time - pitchGroup.startOffset + edgePointSpacing * 0.5)

    local scaledEdgepointSpacing = edgePointSpacing * 0.5 * playrate

    reaper.DeleteEnvelopePointRange(pitchEnvelope, leftEdgeTime - scaledEdgepointSpacing, leftEdgeTime + scaledEdgepointSpacing)
    reaper.DeleteEnvelopePointRange(pitchEnvelope, rightEdgeTime - scaledEdgepointSpacing, rightEdgeTime + scaledEdgepointSpacing)

    reaper.InsertEnvelopePoint(pitchEnvelope, leftEdgeTime, 0, 0, 0, false, true)
    reaper.InsertEnvelopePoint(pitchEnvelope, rightEdgeTime, 0, 0, 0, false, true)
end

function CorrectionGroup:correctPitchGroup(pitchGroup, editOffset, pdSettings)
    if #self.nodes < 2 then return end

    local pitchEnvelope = pitchGroup.envelope
    local playrate = pitchGroup.playrate

    local leftEdgeTime = playrate * (self.nodes[1].time - editOffset)
    local rightEdgeTime = playrate * (self.nodes[#self.nodes].time - editOffset)

    --self:clearEnvelopeContent(pitchGroup, editOffset)

    local prevRelativePointTime = nil
    for pointIndex, point in ipairs(pitchGroup.points) do
        local relativePointTime = point.time - pitchGroup.startOffset
        prevRelativePointTime = prevRelativePointTime or relativePointTime

        if self:timeIsInActiveCorrection(relativePointTime + editOffset) then
            point.correctedPitch = point.pitch
            local targetPitch = self:getPitch(relativePointTime + editOffset)

            CorrectionGroup.correctPitchMod(point, targetPitch, modCorrection)

            reaper.InsertEnvelopePoint(pitchEnvelope, relativePointTime * playrate, point.correctedPitch - point.pitch, 0, 0, false, true)
        end

        self:addZeroPointsToEnvelope(relativePointTime, prevRelativePointTime, pitchEnvelope, playrate)

        prevRelativePointTime = relativePointTime
    end

    local prevNode = nil
    for index, node in ipairs(self.nodes) do
        prevNode = prevNode or node

        if not node.isActive then
            reaper.InsertEnvelopePoint(pitchEnvelope, (node.time + edgePointSpacing * 0.5) * playrate, 0.0, 0, 0, false, true)

        elseif not prevNode.isActive then
            reaper.InsertEnvelopePoint(pitchEnvelope, (node.time - edgePointSpacing * 0.5) * playrate, 0.0, 0, 0, false, true)
        end

        prevNode = node
    end

    CorrectionGroup.addEdgePoints(pitchEnvelope, playrate, leftEdgeTime, rightEdgeTime)
    CorrectionGroup.addEdgePointsToPitchContent(pitchGroup, pitchEnvelope, playrate)
    reaper.Envelope_SortPoints(pitchEnvelope)
end

return CorrectionGroup