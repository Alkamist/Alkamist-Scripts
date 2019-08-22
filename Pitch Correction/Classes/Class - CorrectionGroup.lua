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
                        isActive =   nodeIsActive,
                        saveTime = rawNodeTime
                    } )

                end

            else
                table.insert(outputNodes, {
                    time =       nodeTime,
                    pitch =      nodePitch,
                    isSelected = nodeIsSelected,
                    isActive =   nodeIsActive,
                    saveTime = rawNodeTime
                } )
            end

            searchIndex = searchIndex + string.len(line) + 1

        until false
    end

    return outputNodes
end

function CorrectionGroup:loadSavedCorrections(pitchGroup)
    local loadedNodes = self:getSavedNodesInRange(pitchGroup, pitchGroup.startOffset, pitchGroup.startOffset + pitchGroup.length)

    for index, node in ipairs(loadedNodes) do
        table.insert(self.nodes, node)
    end

    self:sort()
end

function CorrectionGroup:saveCorrections(pitchGroup)
    local saveGroup = CorrectionGroup:new()
    saveGroup.nodes = self:getSavedNodesInRange(pitchGroup)

    for index, node in ipairs(saveGroup.nodes) do
        node.time = node.time - pitchGroup.editOffset
    end

    Lua.arrayRemove(saveGroup.nodes, function(t, i)
        local value = t[i]

        return value.time >= 0.0 and value.time <= pitchGroup.length
    end)

    for index, node in ipairs(self.nodes) do
        local newNode = Lua.copyTable(node)
        newNode.time = newNode.time - pitchGroup.editOffset

        if newNode.time >= 0.0 and newNode.time <= pitchGroup.length then
            table.insert(saveGroup.nodes, newNode)
        end
    end

    saveGroup:sort()



    local correctionString = ""

    for index, node in ipairs(saveGroup.nodes) do
        local nodeTime = node.saveTime or node.time + pitchGroup.startOffset

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

                local targetPitch = self:getPitch(driftPoint.relativeTime, node, nextNode, pitchGroup)

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
    local targetPitch = self:getPitch(point.relativeTime, node, nextNode, pitchGroup)
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

        local nodeTime = node.time - pitchGroup.editOffset

        if nodeTime >= 0.0 and nodeTime <= pitchGroup.length then

            if not node.isActive then
                reaper.InsertEnvelopePoint(pitchGroup.envelope, (nodeTime + edgePointSpacing * 0.5) * pitchGroup.playrate, 0.0, 0, 0, false, true)

            elseif not prevNode.isActive then
                reaper.InsertEnvelopePoint(pitchGroup.envelope, (nodeTime - edgePointSpacing * 0.5) * pitchGroup.playrate, 0.0, 0, 0, false, true)
            end
        end

        prevNode = node
    end
end

function CorrectionGroup:insertCorrectedPointToEnvelope(point, pitchGroup)
    reaper.InsertEnvelopePoint(pitchGroup.envelope, point.relativeTime * pitchGroup.playrate, point.correctedPitch - point.pitch, 0, 0, false, true)
end

function CorrectionGroup:pointIsAffectedByNode(node, nextNode, point, pitchGroup)
    local nodeTime = node.time - pitchGroup.editOffset
    local nextNodeTime = nextNode.time - pitchGroup.editOffset

    return point.relativeTime >= nodeTime and point.relativeTime <= nextNodeTime
end

function CorrectionGroup:getPointsAffectedByNode(node, nextNode, pitchGroup)
    if not node          then return {} end
    if not node.isActive then return {} end
    if not nextNode      then return {} end

    local points = {}

    local firstIndex = pitchGroup:getPointIndexByTime(node.time - pitchGroup.editOffset)
    local lastIndex = pitchGroup:getPointIndexByTime(nextNode.time - pitchGroup.editOffset)

    for index, point in ipairs(pitchGroup.points) do
        if index >= firstIndex and index <= lastIndex then
            table.insert(points, point)
        end
    end

    return points, firstIndex, lastIndex
end

function CorrectionGroup:correctPitchGroupWithSelectedNodes(pitchGroup)
    if #self.nodes < 2 then return end

    for nodeIndex, node in ipairs(self.nodes) do
        local nextNode = nil

        if nodeIndex < #self.nodes then nextNode = self.nodes[nodeIndex + 1] end

        local pointsInNode, firstPointIndex = self:getPointsAffectedByNode(node, nextNode, pitchGroup)

        for pointIndex, point in ipairs(pointsInNode) do

            point.correctedPitch = point.pitch

            self:correctPitchDrift(node, nextNode, point, firstPointIndex + pointIndex, pitchGroup)
            self:correctPitchMod(node, nextNode, point, firstPointIndex + pointIndex, pitchGroup)

            self:insertCorrectedPointToEnvelope(point, pitchGroup)

            --self:addZeroPointsToEnvelope(point, pointIndex, pitchGroup)

        end
    end

    --for pointIndex, point in ipairs(pitchGroup.points) do

        --if self:pointIsInActiveCorrection(point, pitchGroup) then

--            point.correctedPitch = point.pitch
--
--            self:correctPitchDrift(point, pointIndex, pitchGroup)
--            self:correctPitchMod(point, pointIndex, pitchGroup)
--
--            self:insertCorrectedPointToEnvelope(point, pitchGroup)
--
--            self:addZeroPointsToEnvelope(point, pointIndex, pitchGroup)

        --end
    --end

    --self:addEdgePointsToNodes(pitchGroup)
    --self:addEdgePointsToCorrectionGroup(pitchGroup)
    --CorrectionGroup.addEdgePointsToPitchContent(pitchGroup)

    reaper.Envelope_SortPoints(pitchGroup.envelope)
end

function CorrectionGroup:correctPitchGroup(pitchGroup)
    if #self.nodes < 2 then return end

    --for pointIndex, point in ipairs(pitchGroup.points) do

        --[[if self:pointIsInActiveCorrection(point, pitchGroup) then

            point.correctedPitch = point.pitch

            self:correctPitchDrift(point, pointIndex, pitchGroup)
            self:correctPitchMod(point, pointIndex, pitchGroup)

            self:insertCorrectedPointToEnvelope(point, pitchGroup)

            self:addZeroPointsToEnvelope(point, pointIndex, pitchGroup)

        end]]--
    --end

    --self:addEdgePointsToNodes(pitchGroup)
    --self:addEdgePointsToCorrectionGroup(pitchGroup)
    --CorrectionGroup.addEdgePointsToPitchContent(pitchGroup)

    --reaper.Envelope_SortPoints(pitchGroup.envelope)
end

return CorrectionGroup