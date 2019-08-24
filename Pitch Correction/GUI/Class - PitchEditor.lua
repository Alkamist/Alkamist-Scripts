package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

if not GUI then
    reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
    missing_lib = true
    return 0
end


local Lua = require "Various Functions.Lua Functions"
local PitchGroup = require "Pitch Correction.Classes.Class - PitchGroup"
local CorrectionGroup = require "Pitch Correction.Classes.Class - CorrectionGroup"

local mousePitchCorrectionPixelTolerance = 8



GUI.colors["white_keys"] = {112, 112, 112, 255}
GUI.colors["black_keys"] = {81, 81, 81, 255}

GUI.colors["white_key_bg"] = {59, 59, 59, 255}
GUI.colors["black_key_bg"] = {50, 50, 50, 255}

GUI.colors["white_key_lines"] = {65, 65, 65, 255}
GUI.colors["key_lines"] = {255, 255, 255, 20}

GUI.colors["pitch_lines"] = {40, 80, 40, 255}
GUI.colors["pitch_preview_lines"] = {0, 210, 32, 255}

GUI.colors["edit_cursor"] = {255, 255, 255, 70}
GUI.colors["play_cursor"] = {255, 255, 255, 40}

GUI.colors["correction"] = {65, 210, 240, 255}
GUI.colors["correction_inactive"] = {232, 30, 105, 255}

GUI.colors["box_select"] = {255, 255, 255, 150}

local whiteKeysMultiples = {1, 3, 4, 6, 8, 9, 11}
local whiteKeys = {}
for i = 1, 11 do
    for _, value in ipairs(whiteKeysMultiples) do
        table.insert(whiteKeys, (i - 1) * 12 + value)
    end
end



GUI.PitchEditor = GUI.Element:new()
function GUI.PitchEditor:new(name, z, x, y, w, h)
    -- This provides support for creating elms with a keyed table
    local object = (not x and type(z) == "table") and z or {}

    object.name = name
    object.type = "PitchEditor"

    object.z = object.z or z
    object.x = object.x or x
    object.y = object.y or y

    object.w = GUI.w - 4
    object.h = GUI.h - object.y - 2

    object.mousePrev = {
        x = 0,
        y = 0
    }

    object.correctionGroup = CorrectionGroup:new()
    object.selectedNodes = {}

    object.pitchGroups = {}
    object.focus = true

    GUI.redraw_z[z] = true

    setmetatable(object, self)
    self.__index = self

    return object
end



------------------ Helper Functions ------------------

function GUI.PitchEditor:deleteSelectedCorrectionNodes()
    self.selectedNodes = {}

    Lua.arrayRemove(self.correctionGroup.nodes, function(t, i)
        local value = t[i]

        return value.isSelected
    end)

    self:applyPitchCorrections()

    reaper.UpdateArrange()
end

function GUI.PitchEditor:getMouseDistanceToCorrectionNode(index, nodes)
    if nodes == nil then return nil end
    if nodes[index] == nil then return nil end

    local node = nodes[index]

    local nodeX = self:getPixelsFromTime(node.time)
    local nodeY = self:getPixelsFromPitch(node.pitch)

    return Lua.distanceBetweenTwoPoints(nodeX, nodeY, GUI.mouse.x, GUI.mouse.y)
end

function GUI.PitchEditor:getMouseDistanceToLine(index, nodes)
    if nodes == nil then return nil end
    if nodes[index] == nil then return nil end

    local node = nodes[index]
    local nextNode = nodes[index + 1] or node

    local leftHandleX = self:getPixelsFromTime(node.time)
    local leftHandleY = self:getPixelsFromPitch(node.pitch)
    local rightHandleX = self:getPixelsFromTime(nextNode.time)
    local rightHandleY = self:getPixelsFromPitch(nextNode.pitch)

    local mouseDistanceFromLine = Lua.minDistanceBetweenPointAndLineSegment(GUI.mouse.x, GUI.mouse.y, leftHandleX, leftHandleY, rightHandleX, rightHandleY)

    return mouseDistanceFromLine
end

function GUI.PitchEditor:getCorrectionNodeUnderMouse()
    local mouseTime = self:getTimeFromPixels(GUI.mouse.x) or 0
    local mousePitch = self:getPitchFromPixels(GUI.mouse.y) or 0

    local correctionDistances = {}

    for index, node in ipairs(self.correctionGroup.nodes) do
        correctionDistances[index] = self:getMouseDistanceToCorrectionNode(index, self.correctionGroup.nodes)
    end

    local smallestDistanceIndex = nil
    for index, distance in ipairs(correctionDistances) do
        smallestDistanceIndex = smallestDistanceIndex or index

        if distance < correctionDistances[smallestDistanceIndex] then
            smallestDistanceIndex = index
        end
    end

    if smallestDistanceIndex == nil then return nil end

    if correctionDistances[smallestDistanceIndex] <= mousePitchCorrectionPixelTolerance then
        return self.correctionGroup.nodes[smallestDistanceIndex]
    end

    return nil
end

function GUI.PitchEditor:getLineUnderMouse()
    local mouseTime = self:getTimeFromPixels(GUI.mouse.x) or 0
    local mousePitch = self:getPitchFromPixels(GUI.mouse.y) or 0

    local correctionDistances = {}

    for index, node in ipairs(self.correctionGroup.nodes) do
        correctionDistances[index] = self:getMouseDistanceToLine(index, self.correctionGroup.nodes)
    end

    local smallestDistanceIndex = nil
    for index, distance in ipairs(correctionDistances) do
        smallestDistanceIndex = smallestDistanceIndex or index

        if distance < correctionDistances[smallestDistanceIndex] then
            smallestDistanceIndex = index
        end
    end

    if smallestDistanceIndex == nil then return nil end

    if correctionDistances[smallestDistanceIndex] <= mousePitchCorrectionPixelTolerance
    and self.correctionGroup.nodes[smallestDistanceIndex].isActive then

        return { node1 = self.correctionGroup.nodes[smallestDistanceIndex],
                 node2 = self.correctionGroup.nodes[smallestDistanceIndex + 1]
        }
    end

    return nil
end

function GUI.PitchEditor:unselectAllCorrectionNodes()
    for index, node in ipairs(self.correctionGroup.nodes) do
        self:unselectNode(node)
    end

    self:updateExtremeSelectedNodes()
end

function GUI.PitchEditor:selectNode(node)
    if node then
        if not node.isSelected then
            node.isSelected = true
            table.insert(self.selectedNodes, node)

            table.sort(self.selectedNodes, function(a, b) return a.time < b.time end)

            self.selectedNodesStartingIndex = self.correctionGroup:getNodeIndex(self.selectedNodes[1])
        end
    end
end

function GUI.PitchEditor:unselectNode(node)
    if node then
        if node.isSelected then
            node.isSelected = false

            Lua.arrayRemove(self.selectedNodes, function(t, i)
                local value = t[i]

                return value == node
            end)

            if #self.selectedNodes > 0 then

                table.sort(self.selectedNodes, function(a, b) return a.time < b.time end)
                self.selectedNodesStartingIndex = self.correctionGroup:getNodeIndex(self.selectedNodes[1])

            else
                self.selectedNodesStartingIndex = 0
            end
        end
    end
end

function GUI.PitchEditor:setNodeSelected(node, selected)
    if selected then
        self:selectNode(node)

    else
        self:unselectNode(node)
    end
end

function GUI.PitchEditor:applyPitchCorrections(useSelectedNodes)
    for groupIndex, group in ipairs(self.pitchGroups) do
        if useSelectedNodes then
            self.correctionGroup:correctPitchGroupWithSelectedNodes(self.selectedNodes, self.selectedNodesStartingIndex, group)
        else
            reaper.DeleteEnvelopePointRange(group.envelope, 0.0, group.length * group.playrate)
            self.correctionGroup:correctPitchGroup(group)
        end
    end
end

function GUI.PitchEditor:handleNodeCreation(mouseTime, mousePitch)
    self:unselectAllCorrectionNodes()

    local mouseOriginalTime = self:getTimeFromPixels(GUI.mouse.ox)
    local mouseOriginalPitch = self:getPitchFromPixels(GUI.mouse.oy)
    local mouseOriginalSnappedPitch = self:getSnappedPitch(mouseOriginalPitch)

    -- Use snapped pitch if shift is not being held.
    if gfx.mouse_cap & 8 == 0 then
        mouseOriginalPitch = mouseOriginalSnappedPitch
    end

    local newNodeIndex = self.correctionGroup:getNodeIndex( self.correctionGroup:addNode( {

        time = mouseOriginalTime,
        pitch = mouseOriginalPitch,
        isSelected = false,
        isActive = true

    } ) )

    -- If holding control when adding a new node, activate the previous node so it connects.
    if gfx.mouse_cap & 4 == 4 then
        if newNodeIndex > 1 then
            self.correctionGroup.nodes[newNodeIndex - 1].isActive = true
        end
    end

    self.editNode = self.correctionGroup:addNode( {

        time = Lua.clamp(mouseOriginalTime, 0.0, self:getTimeLength()),
        pitch = Lua.clamp(mouseOriginalPitch, 0.0, self:getMaxPitch()),
        isSelected = false,
        isActive = false

    } )

    self:selectNode(self.editNode)

    self:updateExtremeSelectedNodes()
end

function GUI.PitchEditor:handleNodeEditing(mouseTimeChange, mousePitchChange)
    for groupIndex, group in ipairs(self.pitchGroups) do
        self.correctionGroup:clearSelectedNodes(self.selectedNodes, self.selectedNodesStartingIndex, group)
    end

    for index, node in ipairs(self.selectedNodes) do
        node.time = node.time + mouseTimeChange
        node.pitch = node.pitch + mousePitchChange
    end

    self.correctionGroup:sort()
    self:applyPitchCorrections(true)
end

function GUI.PitchEditor:handleLineSelection()
    if not self.editLine.node1 or not self.editLine.node2 then return end

    -- Shift is not held.
    if gfx.mouse_cap & 8 == 0 then
        self:unselectAllCorrectionNodes()
    end

    self:selectNode(self.editLine.node1)
    self:selectNode(self.editLine.node2)

    self:updateExtremeSelectedNodes()
end

function GUI.PitchEditor:setItems(items)
    self.pitchGroups = PitchGroup.getPitchGroupsFromItems(items)

    for groupIndex, group in ipairs(self.pitchGroups) do
        group.editOffset = group.leftTime - self:getTimeLeftBound()
        self.correctionGroup:loadSavedCorrections(group)
    end

    self:applyPitchCorrections()

    self:redraw()
end

function GUI.PitchEditor:setItemsToSelectedItems()
    local itemsAreSelectedOnMultipleTracks = false
    local numSelectedItems = reaper.CountSelectedMediaItems(0)
    local selectedItems = {}

    for i = 1, numSelectedItems do
        local item = reaper.GetSelectedMediaItem(0, i - 1)
        local itemTrack = reaper.GetMediaItemTrack(item)

        if i > 1 then
            local previousItem = reaper.GetSelectedMediaItem(0, i - 2)
            local previousItemTrack = reaper.GetMediaItemTrack(previousItem)

            if itemTrack ~= previousItemTrack then
                itemsAreSelectedOnMultipleTracks = true
            end
        end

        table.insert(selectedItems, item)
    end

    if not itemsAreSelectedOnMultipleTracks then
        self:setItems(selectedItems)
    end
end

function GUI.PitchEditor:initDragZoomAndScroll()
    self.zoomX = self.zoomX or 1.0
    self.zoomY = self.zoomY or 1.0
    self.scrollX = self.scrollX or 0.0
    self.scrollY = self.scrollY or 0.0

    self.zoomXPreDrag = self.zoomXPreDrag or 1.0
    self.zoomYPreDrag = self.zoomYPreDrag or 1.0
    self.scrollXPreDrag = self.scrollXPreDrag or 0.0
    self.scrollYPreDrag = self.scrollYPreDrag or 0.0

    self.shouldZoom = self.shouldZoom or false
    self.shouldDragScroll = self.shouldDragScroll or false

    self.mouse_cap_prev = self.mouse_cap_prev or gfx.mouse_cap
end

function GUI.PitchEditor:analyzePitchGroups()
    for groupIndex, group in ipairs(self.pitchGroups) do
        group:analyze(self.pdSettings)
    end
end

function GUI.PitchEditor:getSnappedPitch(pitch)
    return GUI.round(pitch)
end

function GUI.PitchEditor:getTimeFromPixels(xPixels, zoom, scroll)
    local zoom = zoom or self.zoomX
    local scroll = scroll or self.scrollX

    local relativeX = xPixels - self.x
    return self:getTimeLength() * (scroll + relativeX / (self.w * zoom))
end

function GUI.PitchEditor:getPixelsFromTime(time, zoom, scroll)
    local zoom = zoom or self.zoomX
    local scroll = scroll or self.scrollX

    return self.x + zoom * self.w * (time / self:getTimeLength() - scroll)
end

function GUI.PitchEditor:getPitchFromPixels(yPixels, zoom, scroll)
    local zoom = zoom or self.zoomY
    local scroll = scroll or self.scrollY

    local relativeY = yPixels - self.y
    return self:getMaxPitch() * (1.0 - (scroll + relativeY / (self.h * zoom))) - 0.5
end

function GUI.PitchEditor:getPixelsFromPitch(pitch, zoom, scroll)
    local zoom = zoom or self.zoomY
    local scroll = scroll or self.scrollY

    local pitchRatio = 1.0 - (0.5 + pitch) / self:getMaxPitch()
    return self.y + zoom * self.h * (pitchRatio - scroll)
end

function GUI.PitchEditor:getTimeLeftBound()
    local numPitchGroups = #self.pitchGroups

    if numPitchGroups < 1 then return 0 end

    return self.pitchGroups[1].leftTime
end

function GUI.PitchEditor:getTimeLength()
    local numPitchGroups = #self.pitchGroups

    if numPitchGroups < 1 then return 0 end

    local leftBound = self.pitchGroups[1].leftTime
    local rightBound = self.pitchGroups[numPitchGroups].rightTime

    return rightBound - leftBound
end

function GUI.PitchEditor:getMaxPitch()
    return 128.0
end

function GUI.PitchEditor:moveSelectedNodesDown()
    for index, node in ipairs(self.selectedNodes) do
        if gfx.mouse_cap & 8 == 8 then
            node.pitch = Lua.clamp(node.pitch - 12.0, 0, self:getMaxPitch())
        else
            node.pitch = Lua.clamp(node.pitch - 1.0, 0, self:getMaxPitch())
        end
    end

    self:applyPitchCorrections()
    reaper.UpdateArrange()
end

function GUI.PitchEditor:moveSelectedNodesUp()
    for index, node in ipairs(self.selectedNodes) do
        if gfx.mouse_cap & 8 == 8 then
            node.pitch = Lua.clamp(node.pitch + 12.0, 0, self:getMaxPitch())
        else
            node.pitch = Lua.clamp(node.pitch + 1.0, 0, self:getMaxPitch())
        end
    end

    self:applyPitchCorrections()
    reaper.UpdateArrange()
end

function GUI.PitchEditor:updateExtremeSelectedNodes()
    self.leftSelectedNode = nil
    self.rightSelectedNode = nil
    self.bottomSelectedNode = nil
    self.topSelectedNode = nil

    for index, node in ipairs(self.selectedNodes) do
        self.leftSelectedNode = self.leftSelectedNode or node
        self.rightSelectedNode = self.rightSelectedNode or node
        self.bottomSelectedNode = self.bottomSelectedNode or node
        self.topSelectedNode = self.topSelectedNode or node

        if node.time <= self.leftSelectedNode.time then self.leftSelectedNode = node end
        if node.time >= self.rightSelectedNode.time then self.rightSelectedNode = node end
        if node.pitch <= self.bottomSelectedNode.pitch then self.bottomSelectedNode = node end
        if node.pitch >= self.topSelectedNode.pitch then self.topSelectedNode = node end
    end
end



------------------ Events ------------------

function GUI.PitchEditor:init()
    self:initDragZoomAndScroll()

    self:setItemsToSelectedItems()

    self:drawUI()
end

function GUI.PitchEditor:onupdate()
    self:drawUI()
    self:redraw()
end

function GUI.PitchEditor:onmousedown()
    self.prevMouseTime = self:getTimeFromPixels(GUI.mouse.x)
    self.prevMousePitch = self:getPitchFromPixels(GUI.mouse.y)
    self.prevMouseSnappedPitch = self:getSnappedPitch(self.prevMousePitch)

    local mouseTime = self:getTimeFromPixels(GUI.mouse.x)
    local mousePitch = self:getPitchFromPixels(GUI.mouse.y)
    local mouseSnappedPitch = self:getSnappedPitch(mousePitch)

    -- Use snapped pitch if shift is not being held.
    if gfx.mouse_cap & 8 == 0 then
        mousePitch = mouseSnappedPitch
    end

    self.editNode = self:getCorrectionNodeUnderMouse()
    self.editLine = self:getLineUnderMouse()

    if self.editNode then
        -- Not holding shift.
        if gfx.mouse_cap & 8 == 0 and not self.editNode.isSelected then
            self:unselectAllCorrectionNodes()
        end

        -- Holding alt.
        if gfx.mouse_cap & 16 == 16 then
            if not self.editNode.isSelected then
                self.editNode.isActive = not self.editNode.isActive
            end

            for index, node in ipairs(self.selectedNodes) do
                node.isActive = not node.isActive
            end

            --self:applyPitchCorrections()
            self.altOnEditLDown = true
        end

        -- Holding control.
        if gfx.mouse_cap & 4 == 4 then
            for index, node in ipairs(self.selectedNodes) do
                node.pitch = GUI.round(node.pitch)
            end
        end

        self:selectNode(self.editNode)
        self:updateExtremeSelectedNodes()

    else
        if self.editLine then
            -- If holding alt, deactivate the node responsible for creating the line.
            if gfx.mouse_cap & 16 == 16 then
                self.altOnEditLDown = true
            end

            self:handleLineSelection()
        end

        -- Holding alt.
        if gfx.mouse_cap & 16 == 16 then
            self:unselectAllCorrectionNodes()

            self.editNode = self.correctionGroup:addNode( {

                time = Lua.clamp(mouseTime, 0.0, self:getTimeLength()),
                pitch = Lua.clamp(mousePitch, 0.0, self:getMaxPitch()),
                isSelected = false,
                isActive = false

            } )

            self:selectNode(self.editNode)

            self.correctionGroup:sort()
            self:updateExtremeSelectedNodes()

            local newNodeIndex = self.correctionGroup:getNodeIndex(self.editNode)

            if newNodeIndex > 1 then
                self.correctionGroup.nodes[newNodeIndex - 1].isActive = true
            end

            --self:applyPitchCorrections()
        end
    end

    self:redraw()
end

function GUI.PitchEditor:onmouseup()
    self.lWasDragged = self.lWasDragged or false

    if not self.lWasDragged and not self.altOnEditLDown then
        if self.editNode == nil and self.editLine == nil then
            local playTime = self:getTimeLeftBound() + self:getTimeFromPixels(GUI.mouse.x)
            reaper.SetEditCurPos(playTime, false, true)

            self:unselectAllCorrectionNodes()
        end
    end

    --self:applyPitchCorrections()
    reaper.UpdateArrange()

    self.lWasDragged = false
    self.editNode = nil
    self.editLine = nil
    self.altOnEditLDown = false

    self:redraw()
end

function GUI.PitchEditor:ondrag()
    local mouseTime = self:getTimeFromPixels(GUI.mouse.x)
    local mousePitch = self:getPitchFromPixels(GUI.mouse.y)
    local mouseSnappedPitch = self:getSnappedPitch(mousePitch)

    local mouseTimeChange = mouseTime - self.prevMouseTime
    local mousePitchChange = mousePitch - self.prevMousePitch

    -- Use snapped pitch if shift is not being held.
    if gfx.mouse_cap & 8 == 0 then
        mousePitch = mouseSnappedPitch
        mousePitchChange = mouseSnappedPitch - self.prevMouseSnappedPitch
    end

    if self.leftSelectedNode and self.rightSelectedNode then
        local timeMin = math.min(-self.leftSelectedNode.time, 0)
        local timeMax = math.max(self:getTimeLength() - self.rightSelectedNode.time, 0)
        mouseTimeChange = Lua.clamp(mouseTimeChange, timeMin, timeMax)
    end

    if self.bottomSelectedNode and self.topSelectedNode then
        local pitchMin = math.min(-self.bottomSelectedNode.pitch, 0)
        local pitchMax = math.max(self:getMaxPitch() - self.topSelectedNode.pitch, 0)
        mousePitchChange = Lua.clamp(mousePitchChange, pitchMin, pitchMax)
    end

    if not self.altOnEditLDown then

        if self.editNode == nil and self.editLine == nil then
            self:handleNodeCreation(mouseTime, mousePitch)
        end

        self:handleNodeEditing(mouseTimeChange, mousePitchChange)
    end

    self.lWasDragged = true
    self.prevMouseTime = mouseTime
    self.prevMousePitch = mousePitch
    self.prevMouseSnappedPitch = mouseSnappedPitch

    self:redraw()
end

function GUI.PitchEditor:onmousem_down()
    if GUI.IsInside(self) then
        self.mouseXPreDrag = GUI.mouse.x
        self.scrollXPreDrag = self.scrollX
        self.zoomXPreDrag = self.zoomX

        self.mouseYPreDrag = GUI.mouse.y
        self.scrollYPreDrag = self.scrollY
        self.zoomYPreDrag = self.zoomY

        self.mousePrev.x = GUI.mouse.x
        self.mousePrev.y = GUI.mouse.y

        if gfx.mouse_cap & 8 == 8 then
            self.shouldZoom = true
            self.shouldDragScroll = false
        else
            self.shouldDragScroll = true
            self.shouldZoom = false
        end
    end

    self:redraw()
end

function GUI.PitchEditor:onmousem_up()
    self.shouldZoom = false
    self.shouldDragScroll = false

    self:redraw()
end

function GUI.PitchEditor:onm_drag()
    local x, y, w, h = self.x, self.y, self.w, self.h

    local zoomXSens = 4.0
    local zoomYSens = 4.0

    local scrollXMax = 1.0 - w / (w * self.zoomX)
    local scrollYMax = 1.0 - h / (h * self.zoomY)

    -- Allow toggling shift on and off while middle dragging to switch between zooming
    -- and drag scrolling.
    if gfx.mouse_cap & 8 == 8 and self.mouse_cap_prev & 8 == 0 then
        self.shouldZoom = true
        self.shouldDragScroll = false

        self.mouseXPreDrag = GUI.mouse.x
        self.scrollXPreDrag = self.scrollX
        self.zoomXPreDrag = self.zoomX

        self.mouseYPreDrag = GUI.mouse.y
        self.scrollYPreDrag = self.scrollY
        self.zoomYPreDrag = self.zoomY

    elseif gfx.mouse_cap & 8 == 0 and self.mouse_cap_prev & 8 == 8 then
        self.shouldDragScroll = true
        self.shouldZoom = false

        self.mouseXPreDrag = GUI.mouse.x
        self.scrollXPreDrag = self.scrollX
        self.zoomXPreDrag = self.zoomX

        self.mouseYPreDrag = GUI.mouse.y
        self.scrollYPreDrag = self.scrollY
        self.zoomYPreDrag = self.zoomY
    end

    -- Handle drag scrolling.
    if self.shouldDragScroll then
        -- Horizontal scroll:
        self.scrollX = self.scrollX - (GUI.mouse.x - self.mousePrev.x) / (w * self.zoomX)
        self.scrollX = GUI.clamp(self.scrollX, 0.0, scrollXMax)

        -- Vertical scroll:
        self.scrollY = self.scrollY - (GUI.mouse.y - self.mousePrev.y) / (h * self.zoomY)
        self.scrollY = GUI.clamp(self.scrollY, 0.0, scrollYMax)
    end

    -- Handle zooming.
    if self.shouldZoom then
        -- Horizontal zoom:
        self.zoomX = self.zoomX * (1.0 + zoomXSens * (GUI.mouse.x - self.mousePrev.x) / w)
        self.zoomX = GUI.clamp(self.zoomX, 1.0, 100.0)

        local targetMouseXRatio = self.scrollXPreDrag + self.mouseXPreDrag / (w * self.zoomXPreDrag)
        self.scrollX = targetMouseXRatio - self.mouseXPreDrag / (w * self.zoomX)
        self.scrollX = GUI.clamp(self.scrollX, 0.0, scrollXMax)

        -- Vertical zoom:
        self.zoomY = self.zoomY * (1.0 + zoomYSens * (GUI.mouse.y - self.mousePrev.y) / h)
        self.zoomY = GUI.clamp(self.zoomY, 1.0, 100.0)

        local targetMouseYRatio = self.scrollYPreDrag + self.mouseYPreDrag / (h * self.zoomYPreDrag)
        self.scrollY = targetMouseYRatio - self.mouseYPreDrag / (h * self.zoomY)
        self.scrollY = GUI.clamp(self.scrollY, 0.0, scrollYMax)
    end

    self.mousePrev.x = GUI.mouse.x
    self.mousePrev.y = GUI.mouse.y
    self.mouse_cap_prev = gfx.mouse_cap

    self:redraw()
end

function GUI.PitchEditor:onmouser_down()
    if GUI.IsInside(self) then
        self.boxSelect = { x1 = GUI.mouse.x, y1 = GUI.mouse.y, x2 = GUI.mouse.x, y2 = GUI.mouse.y }
    end

    self:redraw()
end

function GUI.PitchEditor:onmouser_up()
    if self.boxSelect then
        local leftTime = self:getTimeFromPixels( math.min(self.boxSelect.x1, self.boxSelect.x2) )
        local rightTime = self:getTimeFromPixels( math.max(self.boxSelect.x1, self.boxSelect.x2) )
        local bottomPitch = self:getPitchFromPixels( math.max(self.boxSelect.y1, self.boxSelect.y2) )
        local topPitch = self:getPitchFromPixels( math.min(self.boxSelect.y1, self.boxSelect.y2) )

        for index, node in ipairs(self.correctionGroup.nodes) do
            local nodeIsInBoxSelection = node.time >= leftTime and node.time <= rightTime
                                     and node.pitch >= bottomPitch and node.pitch <= topPitch


            if nodeIsInBoxSelection then

                -- Holding shift
                if gfx.mouse_cap & 8 == 8 then
                    self:selectNode(node)

                -- Holding control.
                elseif gfx.mouse_cap & 4 == 4 then
                    self:setNodeSelected(node, not node.isSelected)

                else
                    self:selectNode(node)
                end

            else
                if gfx.mouse_cap & 8 == 0 and gfx.mouse_cap & 4 == 0 then
                    self:unselectNode(node)
                end
            end
        end

        self:updateExtremeSelectedNodes()
    end

    self.boxSelect = nil

    self:redraw()
end

function GUI.PitchEditor:onr_drag()
    if self.boxSelect then
        self.boxSelect.x2 = GUI.mouse.x
        self.boxSelect.y2 = GUI.mouse.y
    end

    self:redraw()
end

function GUI.PitchEditor:onresize()
    self.w = GUI.cur_w - 4
    self.h = GUI.cur_h - self.y - 2

    self:redraw()
end

function GUI.PitchEditor:ondelete()
    GUI.FreeBuffer(self.uiBuffer)
end

function GUI.PitchEditor:ontype()
    local char = GUI.char

    if self.keys[char] then
        self.keys[char](self)
    end

    self:redraw()
end

GUI.PitchEditor.keys = {

    [GUI.chars.DELETE] = function(self)

        self:deleteSelectedCorrectionNodes()

    end,

    [GUI.chars.DOWN] = function(self)

        self:moveSelectedNodesDown()

    end,

    [GUI.chars.UP] = function(self)

        self:moveSelectedNodesUp()

    end,

    -- S -- Save
    [19] = function(self)

        -- Holding control.
        if gfx.mouse_cap & 4 == 4 then
            for groupIndex, group in ipairs(self.pitchGroups) do
                self.correctionGroup:saveCorrections(group)
            end
        end

    end

}



------------------- Drawing -------------------

function GUI.PitchEditor:draw()
    local x, y, w, h = self.x, self.y, self.w, self.h

    gfx.blit(self.uiBuffer, 1, 0, 0, 0, w, h, x, y)
end

function GUI.PitchEditor:drawUI()
    self.uiBuffer = self.uiBuffer or GUI.GetBuffer()
    gfx.setimgdim(self.uiBuffer, -1, -1)
    gfx.setimgdim(self.uiBuffer, self.w, self.h)
    gfx.dest = self.uiBuffer

    --GUI.color("elm_bg")
    --gfx.rect(0, 0, self.w, self.h, 1)

    self:drawKeyBackgrounds()
    self:drawKeyLines()
    self:drawPitchLines()
    self:drawPreviewPitchLines()
    self:drawCorrectionGroup()
    self:drawEditCursor()
    self:drawBoxSelect()
end

function GUI.PitchEditor:lineXIsOnScreen(lineX1, lineX2)
    return lineX1 >= 0 and lineX1 <= self.w
        or lineX2 >= 0 and lineX2 <= self.w
        or lineX1 <= 0 and lineX2 >= self.w
end

function GUI.PitchEditor:drawPitchLines()
    if #self.pitchGroups < 1 then return end

    GUI.color("pitch_lines")

    local groupsTimeOffset = self.pitchGroups[1].leftTime

    for groupIndex, group in ipairs(self.pitchGroups) do
        local groupPixelStart = self:getPixelsFromTime(group.editOffset)
        local groupPixelEnd = self:getPixelsFromTime(group.editOffset + group.length)

        if self:lineXIsOnScreen(groupPixelStart, groupPixelEnd) then
            local drawThreshold = 2.5 * group.minTimePerPoint

            local previousPoint = nil
            local previousPointX = nil
            local previousPointY = nil

            for pointIndex, point in ipairs(group.points) do
                previousPoint = previousPoint or point

                local pitchValue = point.pitch

                local pointX = self:getPixelsFromTime(group.leftTime + point.relativeTime - groupsTimeOffset) - self.x
                local pointY = self:getPixelsFromPitch(pitchValue) - self.y

                previousPointX = previousPointX or pointX
                previousPointY = previousPointY or pointY

                if point.time - previousPoint.time > drawThreshold then
                    previousPointX = pointX
                    previousPointY = pointY
                end

                if self:lineXIsOnScreen(previousPointX, pointX) then
                    gfx.line(previousPointX, previousPointY, pointX, pointY, true)
                end

                previousPoint = point
                previousPointX = pointX
                previousPointY = pointY
            end
        end
    end
end

function GUI.PitchEditor:drawPreviewPitchLines()
    if #self.pitchGroups < 1 then return end

    GUI.color("pitch_preview_lines")

    local groupsTimeOffset = self.pitchGroups[1].leftTime

    for groupIndex, group in ipairs(self.pitchGroups) do
        local groupPixelStart = self:getPixelsFromTime(group.editOffset)
        local groupPixelEnd = self:getPixelsFromTime(group.editOffset + group.length)

        if self:lineXIsOnScreen(groupPixelStart, groupPixelEnd) then
            local drawThreshold = 2.5 * group.minTimePerPoint

            local previousPoint = nil
            local previousPointX = nil
            local previousPointY = nil

            for pointIndex, point in ipairs(group.points) do
                previousPoint = previousPoint or point

                local _, envelopeValue = reaper.Envelope_Evaluate(group.envelope, point.envelopeTime, 44100, 0)

                local pitchValue = point.pitch + envelopeValue

                local pointX = self:getPixelsFromTime(group.leftTime + point.relativeTime - groupsTimeOffset) - self.x
                local pointY = self:getPixelsFromPitch(pitchValue) - self.y

                previousPointX = previousPointX or pointX
                previousPointY = previousPointY or pointY

                if point.time - previousPoint.time > drawThreshold then
                    previousPointX = pointX
                    previousPointY = pointY
                end

                if self:lineXIsOnScreen(previousPointX, pointX) then
                    gfx.line(previousPointX, previousPointY, pointX, pointY, true)
                end

                previousPoint = point
                previousPointX = pointX
                previousPointY = pointY
            end
        end
    end
end

function GUI.PitchEditor:drawKeyBackgrounds()
    local x, y, w, h = self.x, self.y, self.w, self.h

    local lastKeyEnd = self:getPixelsFromPitch(self:getMaxPitch() + 0.5) - y
    for i = 1, math.floor(self:getMaxPitch()) do
        GUI.color("black_key_bg")

        for _, value in ipairs(whiteKeys) do
            if i == value then
                GUI.color("white_key_bg")
            end
        end

        local keyEnd = self:getPixelsFromPitch(self:getMaxPitch() - i + 0.5) - y
        gfx.rect(0, keyEnd, w, keyEnd - lastKeyEnd + 1, 1)

        GUI.color("black_key_bg")

        gfx.line(0, keyEnd, w, keyEnd, false)

        lastKeyEnd = keyEnd
    end
end

function GUI.PitchEditor:drawKeyLines()
    local x, y, w, h = self.x, self.y, self.w, self.h

    local keyHeight = self.zoomY * h * 1.0 / self:getMaxPitch()

    if keyHeight > 16 then
        for i = 1, math.floor(self:getMaxPitch()) do
            GUI.color("key_lines")

            local keyLineHeight = self:getPixelsFromPitch(self:getMaxPitch() - i) - y

            gfx.line(0, keyLineHeight, w, keyLineHeight, false)

            gfx.a = 1.0
        end
    end
end

function GUI.PitchEditor:drawCorrectionGroup()
    local x, y, w, h = self.x, self.y, self.w, self.h

    local circleRadii = 3

    local prevNode = nil

    for index, node in ipairs(self.correctionGroup.nodes) do
        prevNode = prevNode or node

        local leftTimePixels = self:getPixelsFromTime(prevNode.time) - x
        local rightTimePixels = self:getPixelsFromTime(node.time) - x

        if self:lineXIsOnScreen(leftTimePixels, rightTimePixels) then

            local leftPitchPixels = self:getPixelsFromPitch(prevNode.pitch) - y
            local rightPitchPixels = self:getPixelsFromPitch(node.pitch) - y

            local angle = math.atan(rightPitchPixels - leftPitchPixels, rightTimePixels - leftTimePixels)
            local timeOffset = math.cos(angle) * (circleRadii + 1)
            local pitchOffset = math.sin(angle) * (circleRadii + 1)
            local leftLineTimePixels = leftTimePixels + timeOffset
            local rightLineTimePixels = rightTimePixels - timeOffset
            local leftLinePitchPixels = leftPitchPixels + pitchOffset
            local rightLinePitchPixels = rightPitchPixels - pitchOffset

            GUI.color("correction")

            if prevNode.isActive and index > 1 then
                gfx.line(leftLineTimePixels, leftLinePitchPixels, rightLineTimePixels, rightLinePitchPixels, true)
            end

            if not node.isActive then GUI.color("correction_inactive") end

            gfx.circle(rightTimePixels, rightPitchPixels, circleRadii, node.isSelected, true)

        end

        prevNode = node
    end
end

function GUI.PitchEditor:drawEditCursor()
    local x, y, w, h = self.x, self.y, self.w, self.h

    local editCursorPosition = reaper.GetCursorPositionEx(0)
    local editCursorPixels = self:getPixelsFromTime(editCursorPosition - self:getTimeLeftBound()) - x

    local playPosition = reaper.GetPlayPositionEx(0)
    local playPositionPixels = self:getPixelsFromTime(playPosition - self:getTimeLeftBound()) - x

    GUI.color("edit_cursor")

    gfx.line(editCursorPixels, 0, editCursorPixels, h, false)

    local projectPlaystate = reaper.GetPlayStateEx(0)
    local projectIsPlaying = projectPlaystate & 1 == 1 or projectPlaystate & 4 == 4
    if projectIsPlaying then
        GUI.color("play_cursor")
        gfx.line(playPositionPixels, 0, playPositionPixels, h, false)
    end

    gfx.a = 1.0
end

function GUI.PitchEditor:drawBoxSelect()
    if self.boxSelect then
        GUI.color("box_select")
        local boxX = math.min(self.boxSelect.x1, self.boxSelect.x2) - self.x
        local boxY = math.min(self.boxSelect.y1, self.boxSelect.y2) - self.y
        local boxW = math.abs(self.boxSelect.x1 - self.boxSelect.x2)
        local boxH = math.abs(self.boxSelect.y1 - self.boxSelect.y2)

        gfx.rect(boxX, boxY, boxW, boxH, 0)
        gfx.a = gfx.a * 0.07
        gfx.rect(boxX + 1, boxY + 1, boxW - 1, boxH - 1, 1)

        gfx.a = 1.0
    end
end