package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Lua = require "Various Functions.Lua Functions"
local PitchGroup = require "Pitch Correction.Classes.Class - PitchGroup"



-- Pitch correction settings:
local averageCorrection = 0.0
local modCorrection = 0.3
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

function CorrectionGroup:getSavedNodesInRange(pitchGroup, leftTime, rightTime)
    local _, extState = reaper.GetProjExtState(0, "Alkamist_PitchCorrection", pitchGroup.takeName .. "_corrections")

    local outputNodes = {}

    local headerStart, headerEnd = string.find(extState, "<NODES")

    if headerStart and headerEnd then

        local searchIndex = headerEnd + 1

        repeat

            local line = string.match(extState, "([^\r\n]+)", searchIndex)
            if line == nil then break end
            if string.match(line, ">") then break end

            local rawNodeTime = tonumber( line:match("([%.%-%d]+) [%.%-%d]+ [%.%-%d]+ [%.%-%d]+") )

            local nodeTime = rawNodeTime + pitchGroup.editOffset - pitchGroup.startOffset
            local nodePitch = tonumber( line:match("[%.%-%d]+ ([%.%-%d]+) [%.%-%d]+ [%.%-%d]+") )
            local nodeIsSelected = tonumber( line:match("[%.%-%d]+ [%.%-%d]+ ([%.%-%d]+) [%.%-%d]+") ) > 0
            local nodeIsActive = tonumber( line:match("[%.%-%d]+ [%.%-%d]+ [%.%-%d]+ ([%.%-%d]+)") ) > 0

            if leftTime and rightTime then

                if rawNodeTime >= leftTime and rawNodeTime <= rightTime then

                    table.insert(outputNodes, {
                        time =       nodeTime,
                        pitch =      nodePitch,
                        isSelected = nodeIsSelected,
                        isActive =   nodeIsActive
                    } )

                end

            else
                table.insert(outputNodes, {
                    time =       nodeTime,
                    pitch =      nodePitch,
                    isSelected = nodeIsSelected,
                    isActive =   nodeIsActive
                } )
            end

            searchIndex = searchIndex + string.len(line) + 1

        until false
    end

    return outputNodes
end

function CorrectionGroup:loadSavedCorrections(pitchGroup)
    self.nodes = self:getSavedNodesInRange(pitchGroup, pitchGroup.startOffset, pitchGroup.startOffset + pitchGroup.length)

    self:sort()
end

function CorrectionGroup:saveCorrections(pitchGroup)
    local saveGroup = CorrectionGroup:new()
    saveGroup.nodes = self:getSavedNodesInRange(pitchGroup)

    Lua.arrayRemove(saveGroup.nodes, function(t, i)
        local value = t[i]

        return value.time >= pitchGroup.startOffset and value.time <= pitchGroup.startOffset + pitchGroup.length
    end)

    for index, node in ipairs(self.nodes) do
        table.insert(saveGroup.nodes, node)
    end

    saveGroup:sort()



    local correctionString = ""

    for index, node in ipairs(saveGroup.nodes) do
        local nodeTime = node.time + pitchGroup.startOffset - pitchGroup.editOffset

        correctionString = correctionString .. string.format("    %f %f %f %f\n", nodeTime,
                                                                                  node.pitch,
                                                                                  node.isSelected and 1 or 0,
                                                                                  node.isActive and 1 or 0)
    end

    local dataString = "<NODES\n" ..
                            correctionString ..
                        ">\n"

    reaper.SetProjExtState(0, "Alkamist_PitchCorrection", pitchGroup.takeName .. "_corrections", dataString)
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

function CorrectionGroup:getPitch(time, pitchGroup)
    local relativeTime = time + pitchGroup.editOffset

    local leftNode, rightNode = self:getBindingNodes(relativeTime)

    if leftNode and rightNode then
        local timeRatio = (relativeTime - leftNode.time) / (rightNode.time - leftNode.time)
        local pitch = leftNode.pitch + (rightNode.pitch - leftNode.pitch) * timeRatio

        return pitch
    end

    if leftNode then
        return leftNode.pitch
    end

    if rightNode then
        return rightNode.pitch
    end

    return nil
end

function CorrectionGroup:pointIsInActiveCorrection(point, pitchGroup)
    local leftNode, rightNode = self:getBindingNodes(point.relativeTime + pitchGroup.editOffset)

    if leftNode and rightNode then
        return leftNode.isActive
    end

    return false
end

function CorrectionGroup:correctPitchDrift(point, pointIndex, pitchGroup)
    local maxDriftPoints = math.ceil(driftCorrectionSpeed / pitchGroup.minTimePerPoint)
    local numPitchPoints = #pitchGroup.points

    local driftAverage = 0
    local numDriftPoints = 0
    for i = 1, maxDriftPoints do
        local accessIndex = pointIndex + i - math.ceil(maxDriftPoints * 0.5)

        if accessIndex >= 1 and accessIndex <= numPitchPoints then
            local driftPoint = pitchGroup.points[accessIndex]
            local correctionRadius = driftCorrectionSpeed * 0.5

            local driftPointIsInCorrectionRadius = driftPoint.time >= point.time - correctionRadius
                                               and driftPoint.time <= point.time + correctionRadius

            if driftPointIsInCorrectionRadius and self:pointIsInActiveCorrection(driftPoint, pitchGroup) then

                local targetPitch = self:getPitch(driftPoint.relativeTime, pitchGroup)

                if targetPitch then
                    driftAverage = driftAverage + driftPoint.pitch - targetPitch

                    numDriftPoints = numDriftPoints + 1
                end

            end
        end
    end

    if numDriftPoints > 0 then
        driftAverage = driftAverage / numDriftPoints
    end

    local pitchCorrection = -driftAverage * driftCorrection

    point.correctedPitch = point.correctedPitch + pitchCorrection
end

function CorrectionGroup:correctPitchMod(point, pointIndex, pitchGroup)
    local targetPitch = self:getPitch(point.relativeTime, pitchGroup)
    if not targetPitch then return end

    local modDeviation = point.correctedPitch - targetPitch
    local pitchCorrection = -modDeviation * modCorrection

    point.correctedPitch = point.correctedPitch + pitchCorrection
end

function CorrectionGroup:addZeroPointsToEnvelope(point, pointIndex, pitchGroup)
    local pointTime = point.time - pitchGroup.startOffset
    local prevPointTime = 0.0
    local timeToPrevPoint = 0.0

    if pointIndex > 1 then
        prevPointTime = pitchGroup.points[pointIndex - 1].relativeTime
        timeToPrevPoint = point.relativeTime - prevPointTime
    end

    if zeroPointThreshold then
        if timeToPrevPoint >= zeroPointThreshold then
            local zeroPoint1Time = pitchGroup.playrate * (point.relativeTime - zeroPointSpacing)
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

function CorrectionGroup:insertCorrectedPointToEnvelope(point, pitchGroup)
    reaper.InsertEnvelopePoint(pitchGroup.envelope, point.relativeTime * pitchGroup.playrate, point.correctedPitch - point.pitch, 0, 0, false, true)
end

function CorrectionGroup:correctPitchGroup(pitchGroup)
    if #self.nodes < 2 then return end

    for pointIndex, point in ipairs(pitchGroup.points) do

        if self:pointIsInActiveCorrection(point, pitchGroup) then

            point.correctedPitch = point.pitch

            self:correctPitchDrift(point, pointIndex, pitchGroup)
            self:correctPitchMod(point, pointIndex, pitchGroup)

            self:insertCorrectedPointToEnvelope(point, pitchGroup)

            self:addZeroPointsToEnvelope(point, pointIndex, pitchGroup)

        end
    end

    self:addEdgePointsToNodes(pitchGroup)
    self:addEdgePointsToCorrectionGroup(pitchGroup)
    CorrectionGroup.addEdgePointsToPitchContent(pitchGroup)

    reaper.Envelope_SortPoints(pitchGroup.envelope)
end

return CorrectionGroup