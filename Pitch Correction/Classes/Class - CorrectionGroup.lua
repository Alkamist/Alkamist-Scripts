package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Lua = require "Various Functions.Lua Functions"
local Reaper = require "Various Functions.Reaper Functions"
local PitchGroup = require "Pitch Correction.Classes.Class - PitchGroup"



-- Pitch correction settings:
local modCorrection = 0.3
local driftCorrection = 1.0
local driftCorrectionSpeed = 0.17
local zeroPointThreshold = 0.09
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



function CorrectionGroup:updateSourceTimes(pitchGroup)
    for index, node in ipairs(self.nodes) do
        node.sourceTime = Reaper.getSourcePosition(pitchGroup.take, node.time)
    end
end

function CorrectionGroup:loadSavedCorrections(pitchGroup)
    local fullFileName = reaper.GetProjectPath("") .. "\\" .. pitchGroup.takeName .. ".correction"

    local lines = Lua.getFileLines(fullFileName)

    self.nodes = {}

    local headerLeft = nil
    local headerRight = nil
    local keys = {}
    local recordPoints = false
    local nodeIndex = 1

    local leftBound = Reaper.getSourcePosition(pitchGroup.take, 0.0)
    local rightBound = Reaper.getSourcePosition(pitchGroup.take, pitchGroup.length)

    for lineNumber, line in ipairs(lines) do

        if line:match(">") then
            recordPoints = false
            keys = {}
        end

        if line:match("<CORRECTION") then
            recordPoints = true

            for key in string.gmatch(line, " (%a+)") do
                table.insert(keys, key)
            end
        end

        if recordPoints then

            local lineValues = Lua.getStringValues(line)

            if #lineValues >= #keys then
                local node = {}

                for index, key in ipairs(keys) do
                    if key == "isActive" or key == "isSelected" then
                        node[key] = lineValues[index] > 0
                    else
                        node[key] = lineValues[index]
                    end
                end

                if node.sourceTime >= leftBound and node.sourceTime <= rightBound then
                    self.nodes[nodeIndex] = node
                    self.nodes[nodeIndex].time = Reaper.getRealPosition(pitchGroup.take, self.nodes[nodeIndex].sourceTime)

                    nodeIndex = nodeIndex + 1
                end
            end
        end
    end

    self:sort()
end

function CorrectionGroup.getSaveString(correctionGroup, pitchGroup)
    local pitchKeyString = "sourceTime pitch isActive isSelected"
    local pitchString = ""

    for pointIndex, node in ipairs(correctionGroup.nodes) do
        pitchString = pitchString .. tostring(node.sourceTime) .. " " ..
                                     tostring(node.pitch) .. " " ..
                                     tostring(node.isActive and 1 or 0) .. " " ..
                                     tostring(node.isSelected and 1 or 0) .. "\n"
    end

    return "LEFTBOUND " .. tostring(pitchGroup.startOffset) .. "\n" ..

           "RIGHTBOUND " .. tostring(pitchGroup.startOffset + pitchGroup.length) .. "\n" ..

           "<CORRECTION " .. pitchKeyString .. "\n" ..
           pitchString ..
           ">\n"
end

function CorrectionGroup:saveCorrections(pitchGroup)
    self:updateSourceTimes(pitchGroup)

    local saveString = CorrectionGroup.getSaveString(self, pitchGroup)

    local fullFileName = reaper.GetProjectPath("") .. "\\" .. pitchGroup.takeName .. ".correction"
    local file, err = io.open(fullFileName, "w")

    file:write(saveString)
end



function CorrectionGroup:copyNodes(nodes)
    local copyGroup = CorrectionGroup:new()

    for index, node in ipairs(nodes) do
        local newNode = Lua.copyTable(node)

        table.insert(copyGroup.nodes, newNode)
    end

    local copyString = self:getSaveString(copyGroup)

    reaper.SetExtState("Alkamist_PitchCorrection", "clipboard", copyString, true)
end

function CorrectionGroup:pasteNodes(offset)
    local pasteString = reaper.GetExtState("Alkamist_PitchCorrection", "clipboard")
    local pastedNodes = self:getNodesFromSaveString(pasteString)

    local firstNodeSpacing = nil
    for index, node in ipairs(pastedNodes) do
        firstNodeSpacing = firstNodeSpacing or node.time

        if offset then
            node.time = node.time - firstNodeSpacing + offset
        end

        node.isSelected = true
        table.insert( self.nodes, node )
    end

    self:sort()
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

function CorrectionGroup:getPitch(time, node, nextNode, pitchGroup)
    local relativeTime = time + pitchGroup.editOffset

    if node and nextNode then
        local timeRatio = (relativeTime - node.time) / (nextNode.time - node.time)
        local pitch = node.pitch + (nextNode.pitch - node.pitch) * timeRatio

        return pitch
    end

    if node then
        return node.pitch
    end

    if nextNode then
        return nextNode.pitch
    end

    return nil
end

function CorrectionGroup:correctPitchDrift(node, nextNode, point, pointIndex, pitchGroup)
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

            if driftPointIsInCorrectionRadius and self:pointIsAffectedByNode(node, nextNode, driftPoint, pitchGroup) then

                local targetPitch = self:getPitch(driftPoint.time, node, nextNode, pitchGroup)

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

function CorrectionGroup:correctPitchMod(node, nextNode, point, pointIndex, pitchGroup)
    local targetPitch = self:getPitch(point.time, node, nextNode, pitchGroup)
    if not targetPitch then return end

    local modDeviation = point.correctedPitch - targetPitch
    local pitchCorrection = -modDeviation * modCorrection

    point.correctedPitch = point.correctedPitch + pitchCorrection
end

function CorrectionGroup:addZeroPointsToEnvelope(node, nextNode, point, pointIndex, firstPointIndex, lastPointIndex, pitchGroup)
    local prevPointTime = 0.0
    local nextPointTime = 0.0
    local timeToPrevPoint = 0.0
    local timeToNextPoint = 0.0

    if pointIndex > 1 then
        prevPointTime = pitchGroup.points[pointIndex - 1].time
        timeToPrevPoint = point.time - prevPointTime
    end

    if pointIndex < #pitchGroup.points then
        nextPointTime = pitchGroup.points[pointIndex + 1].time
        timeToNextPoint = nextPointTime - point.time
    end

    if zeroPointThreshold then
        local scaledZeroPointThreshold = zeroPointThreshold / pitchGroup.playrate

        if timeToPrevPoint >= scaledZeroPointThreshold or pointIndex == 1 then
            local zeroPointTime = pitchGroup.playrate * (point.time - zeroPointSpacing)
            reaper.DeleteEnvelopePointRange(pitchGroup.envelope, zeroPointTime - zeroPointSpacing * 0.5, zeroPointTime + zeroPointSpacing * 0.5)
            reaper.InsertEnvelopePoint(pitchGroup.envelope, zeroPointTime, 0, 0, 0, false, true)
        end

        if timeToNextPoint >= scaledZeroPointThreshold or pointIndex == #pitchGroup.points then
            local zeroPointTime = pitchGroup.playrate * (point.time + zeroPointSpacing)
            reaper.DeleteEnvelopePointRange(pitchGroup.envelope, zeroPointTime - zeroPointSpacing * 0.5, zeroPointTime + zeroPointSpacing * 0.5)
            reaper.InsertEnvelopePoint(pitchGroup.envelope, zeroPointTime, 0, 0, 0, false, true)
        end
    end
end

function CorrectionGroup:addEdgePointsToNode(node, nextNode, nodeIndex, pitchGroup)
    local nodeTime = node.time - pitchGroup.editOffset
    local nextNodeTime = nextNode.time - pitchGroup.editOffset

    local prevNode = nil
    if nodeIndex > 1 then prevNode = self.nodes[nodeIndex - 1] end

    if nodeTime >= 0.0 and nodeTime <= pitchGroup.length then

        if node.isActive and nodeIndex == 1 then
            reaper.InsertEnvelopePoint(pitchGroup.envelope, (nodeTime + 0.00001) * pitchGroup.playrate, 0.0, 0, 0, false, true)
        end

        if node.isActive and not nextNode.isActive then
            reaper.InsertEnvelopePoint(pitchGroup.envelope, (nextNodeTime - 0.00001) * pitchGroup.playrate, 0.0, 0, 0, false, true)
        end

        if node.isActive and prevNode then
            if not prevNode.isActive then
                reaper.InsertEnvelopePoint(pitchGroup.envelope, (nodeTime + 0.00001) * pitchGroup.playrate, 0.0, 0, 0, false, true)
            end
        end
    end
end

function CorrectionGroup:insertCorrectedPointToEnvelope(point, pitchGroup)
    reaper.InsertEnvelopePoint(pitchGroup.envelope, point.time * pitchGroup.playrate, point.correctedPitch - point.pitch, 0, 0, false, true)
end

function CorrectionGroup:pointIsAffectedByNode(node, nextNode, point, pitchGroup)
    local nodeTime = node.time - pitchGroup.editOffset
    local nextNodeTime = nextNode.time - pitchGroup.editOffset

    return point.time >= nodeTime and point.time <= nextNodeTime
end

function CorrectionGroup:getPointsAffectedByNode(node, nextNode, pitchGroup)
    if not node               then return {}, 0, 0 end
    if not node.isActive      then return {}, 0, 0 end
    if not nextNode           then return {}, 0, 0 end
    if #pitchGroup.points < 1 then return {}, 0, 0 end

    local timeStart = pitchGroup.editOffset
    local timeEnd = timeStart + pitchGroup.length

    if node.time >= timeStart     and node.time <= timeEnd
    or nextNode.time >= timeStart and nextNode.time <= timeEnd
    or node.time <= timeStart     and nextNode.time >= timeEnd then

        local points = {}

        local firstIndex = pitchGroup:getPointIndexByTime(node.time - pitchGroup.editOffset, false)
        local lastIndex = pitchGroup:getPointIndexByTime(nextNode.time - pitchGroup.editOffset, true)

        for index, point in ipairs(pitchGroup.points) do
            if index >= firstIndex and index <= lastIndex then
                table.insert(points, point)
            end
        end

        return points, firstIndex, lastIndex

    end

    return {}, 0, 0
end

function CorrectionGroup:clearSelectedNodes(selectedNodes, selectedNodesStartingIndex, pitchGroup)
    if #self.nodes < 2 then return end

    for nodeIndex, node in ipairs(selectedNodes) do

        local nodeFullIndex = selectedNodesStartingIndex + nodeIndex - 1

        local prevNode = nil
        if nodeFullIndex > 1 then prevNode = self.nodes[nodeFullIndex - 1] end

        local nextNode = nil
        if nodeFullIndex < #self.nodes then nextNode = self.nodes[nodeFullIndex + 1] end

        if prevNode then
            if not prevNode.isSelected and prevNode.isActive then
                local nodeTime = prevNode.time - pitchGroup.editOffset
                local nextNodeTime = node.time - pitchGroup.editOffset
                reaper.DeleteEnvelopePointRange(pitchGroup.envelope, nodeTime * pitchGroup.playrate, nextNodeTime * pitchGroup.playrate)
            end
        end

        if nextNode then
            if node.isActive then
                local nodeTime = node.time - pitchGroup.editOffset
                local nextNodeTime = nextNode.time - pitchGroup.editOffset
                reaper.DeleteEnvelopePointRange(pitchGroup.envelope, nodeTime * pitchGroup.playrate, nextNodeTime * pitchGroup.playrate)
            end
        end
    end

    reaper.Envelope_SortPoints(pitchGroup.envelope)
end

function CorrectionGroup:correctPitchGroupWithNodes(node, nextNode, nodeIndex, pitchGroup)
    if node.isActive then
        local nodeTime = node.time - pitchGroup.editOffset
        local nextNodeTime = nextNode.time - pitchGroup.editOffset

        reaper.DeleteEnvelopePointRange(pitchGroup.envelope, nodeTime * pitchGroup.playrate, nextNodeTime * pitchGroup.playrate)

        local pointsInNode, firstPointIndex, lastPointIndex = self:getPointsAffectedByNode(node, nextNode, pitchGroup)

        for pointIndex, point in ipairs(pointsInNode) do

            local pointGroupIndex = firstPointIndex + pointIndex - 1

            point.correctedPitch = point.pitch

            self:correctPitchDrift(node, nextNode, point, pointGroupIndex, pitchGroup)
            self:correctPitchMod(node, nextNode, point, pointGroupIndex, pitchGroup)

            self:insertCorrectedPointToEnvelope(point, pitchGroup)

            self:addZeroPointsToEnvelope(node, nextNode, point, pointGroupIndex, firstPointIndex, lastPointIndex, pitchGroup)
        end
    end

    self:addEdgePointsToNode(node, nextNode, nodeIndex, pitchGroup)
end

function CorrectionGroup:correctPitchGroupWithSelectedNodes(selectedNodes, selectedNodesStartingIndex, pitchGroup)
    if #self.nodes < 2 then return end

    for nodeIndex, node in ipairs(selectedNodes) do

        local nodeFullIndex = selectedNodesStartingIndex + nodeIndex - 1

        local prevNode = nil
        if nodeFullIndex > 1 then prevNode = self.nodes[nodeFullIndex - 1] end

        local nextNode = nil
        if nodeFullIndex < #self.nodes then nextNode = self.nodes[nodeFullIndex + 1] end

        if prevNode then
            if not prevNode.isSelected then
                self:correctPitchGroupWithNodes(prevNode, node, nodeFullIndex - 1, pitchGroup)
            end
        end

        if nextNode then
            self:correctPitchGroupWithNodes(node, nextNode, nodeFullIndex, pitchGroup)
        end
    end

    reaper.Envelope_SortPoints(pitchGroup.envelope)
end

function CorrectionGroup:correctPitchGroup(pitchGroup)
    if #self.nodes < 2 then return end

    for nodeIndex, node in ipairs(self.nodes) do

        local prevNode = nil
        if nodeIndex > 1 then prevNode = self.nodes[nodeIndex - 1] end

        local nextNode = nil
        if nodeIndex < #self.nodes then nextNode = self.nodes[nodeIndex + 1] end

        if prevNode then
            if not prevNode.isSelected then
                self:correctPitchGroupWithNodes(prevNode, node, nodeIndex - 1, pitchGroup)
            end
        end

        if nextNode then
            self:correctPitchGroupWithNodes(node, nextNode, nodeIndex, pitchGroup)
        end
    end

    reaper.Envelope_SortPoints(pitchGroup.envelope)
end

return CorrectionGroup