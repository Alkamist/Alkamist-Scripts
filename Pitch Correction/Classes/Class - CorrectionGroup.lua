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

function CorrectionGroup:correctPitchGroup(pitchGroup, editOffset, pdSettings)
    if #self.nodes < 2 then return end

    local pitchEnvelope = pitchGroup.envelope
    local playrate = pitchGroup.playrate

    reaper.DeleteEnvelopePointRange(pitchEnvelope, playrate * (self.nodes[1].time - editOffset), playrate * (self.nodes[#self.nodes].time - editOffset))

    for pointIndex, point in ipairs(pitchGroup.points) do
        local relativePointTime = point.time - pitchGroup.startOffset

        if self:timeIsInActiveCorrection(relativePointTime + editOffset) then
            point.correctedPitch = point.pitch
            local targetPitch = self:getPitch(relativePointTime + editOffset)

            CorrectionGroup.correctPitchMod(point, targetPitch, modCorrection)

            reaper.InsertEnvelopePoint(pitchEnvelope, relativePointTime * playrate, point.correctedPitch - point.pitch, 0, 0, false, true)
        end
    end

    --CorrectionGroup.addEdgePointsToPitchContent(pitchGroup.points, pitchEnvelope, playrate)
    reaper.Envelope_SortPoints(pitchEnvelope)
end

return CorrectionGroup