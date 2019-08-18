package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

if not GUI then
    reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
    missing_lib = true
    return 0
end


local Lua = require "Various Functions.Lua Functions"
local PitchGroup = require "Pitch Correction.Classes.Class - PitchGroup"
local CorrectionGroup = require "Pitch Correction.Classes.Class - CorrectionGroup"

local mousePitchCorrectionPixelTolerance = 5



GUI.colors["white_keys"] = {112, 112, 112, 255}
GUI.colors["black_keys"] = {81, 81, 81, 255}

GUI.colors["white_key_bg"] = {59, 59, 59, 255}
GUI.colors["black_key_bg"] = {50, 50, 50, 255}

GUI.colors["white_key_lines"] = {65, 65, 65, 255}
GUI.colors["key_lines"] = {255, 255, 255, 80}

GUI.colors["pitch_lines"] = {40, 80, 40, 255}
GUI.colors["pitch_preview_lines"] = {0, 210, 32, 255}

GUI.colors["edit_cursor"] = {255, 255, 255, 180}
GUI.colors["play_cursor"] = {255, 255, 255, 120}

GUI.colors["pitch_correction"] = {32, 118, 167, 255}
GUI.colors["pitch_correction_selected"] = {65, 210, 240, 255}

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

    object.orig_w = object.w
    object.orig_h = object.h

    object.mousePrev = {
        x = 0,
        y = 0
    }

    object.correctionGroup = CorrectionGroup:new()

    object.keyWidthMult = 0.05
    object.keyWidth = object.w * object.keyWidthMult

    object.pitchGroups = {}

    GUI.redraw_z[z] = true

    setmetatable(object, self)
    self.__index = self

    return object
end

function GUI.PitchEditor:init()
    self:initDragZoomAndScroll()

    self:setItemsToSelectedItems()

    self:drawKeyBackgrounds()
    self:drawBackground()
    self:drawKeyLines()
    self:drawPitchLines()
    self:drawPreviewPitchLines()
    self:drawCorrectionGroup()
    self:drawEditCursor()
    self:drawKeys()

    self:redraw()
end

function GUI.PitchEditor:draw()
    local x, y, w, h = self.x, self.y, self.w, self.h

    if self.backgroundBuff then
        gfx.blit(self.backgroundBuff, 1, 0, 0, 0, self.orig_w, self.orig_h, x, y, w, h)
    end

    if self.keyBackgroundBuff then
        gfx.blit(self.keyBackgroundBuff, 1, 0, 0, 0, w, h, x, y)
    end

    if self.keyLinesBuff then
        gfx.blit(self.keyLinesBuff, 1, 0, 0, 0, w, h, x, y)
    end

    if self.pitchLinesBuff then
        gfx.blit(self.pitchLinesBuff, 1, 0, 0, 0, w, h, x, y)
    end

    if self.previewLinesBuff then
        gfx.blit(self.previewLinesBuff, 1, 0, 0, 0, w, h, x, y)
    end

    if self.correctionGroupBuff then
        gfx.blit(self.correctionGroupBuff, 1, 0, 0, 0, w, h, x, y)
    end

    if self.editCursorBuff then
        gfx.blit(self.editCursorBuff, 1, 0, 0, 0, w, h, x, y)
    end

    if self.keysBuff then
        gfx.blit(self.keysBuff, 1, 0, 0, 0, w, h, x, y)
    end
end

function GUI.PitchEditor:deleteSelectedCorrectionNodes()
    Lua.arrayRemove(self.correctionGroup.nodes, function(t, i)
        local value = t[i]

        return value.isSelected
    end)

    reaper.UpdateArrange()
end

function GUI.PitchEditor:getMouseDistanceToCorrectionNode(index, nodes)
    if nodes == nil then return nil end
    if nodes[index] == nil then return nil end

    --[[local node = nodes[index]
    local nextNode = nodes[index + 1] or node

    local leftHandleX = self:getPixelsFromTime(node.time)
    local leftHandleY = self:getPixelsFromPitch(node.pitch)
    local rightHandleX = self:getPixelsFromTime(nextNode.time)
    local rightHandleY = self:getPixelsFromPitch(nextNode.pitch)

    local mouseDistanceFromPitchCorrectionLine = Lua.minDistanceBetweenPointAndLineSegment(GUI.mouse.x, GUI.mouse.y, leftHandleX, leftHandleY, rightHandleX, rightHandleY)

    return mouseDistanceFromPitchCorrectionLine]]--

    local node = nodes[index]

    local nodeX = self:getPixelsFromTime(node.time)
    local nodeY = self:getPixelsFromPitch(node.pitch)

    return Lua.distanceBetweenTwoPoints(nodeX, nodeY, GUI.mouse.x, GUI.mouse.y)
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

function GUI.PitchEditor:unselectAllCorrectionNodes()
    for index, node in ipairs(self.correctionGroup.nodes) do
        node.isSelected = false
    end
end

function GUI.PitchEditor:onmousedown()
    self.prevMouseTime = self:getTimeFromPixels(GUI.mouse.x)
    self.prevMousePitch = self:getPitchFromPixels(GUI.mouse.y)

    self.editNode = self:getCorrectionNodeUnderMouse()

    if self.editNode then
        -- Not holding shift.
        if gfx.mouse_cap & 8 == 0 and not self.editNode.isSelected then
            self:unselectAllCorrectionNodes()
        end

        self.editNode.isSelected = true
    end

    self:drawPreviewPitchLines()
    self:drawCorrectionGroup()

    self:redraw()
end

function GUI.PitchEditor:onmouseup()
    self.lWasDragged = self.lWasDragged or false

    if not self.lWasDragged then
        local nodeUnderMouse = self:getCorrectionNodeUnderMouse()

        if nodeUnderMouse == nil then
            local playTime = self:getTimeLeftBound() + self:getTimeFromPixels(GUI.mouse.x)
            reaper.SetEditCurPos(playTime, false, true)

            self:drawEditCursor()

            self:unselectAllCorrectionNodes()

        -- Not holding shift:
        elseif gfx.mouse_cap & 8 == 0 then
            self:unselectAllCorrectionNodes()
            nodeUnderMouse.isSelected = true
        end
    end

    self.lWasDragged = false
    self.editNode = nil

    self:drawCorrectionGroup()

    self:redraw()
end

function GUI.PitchEditor:ondrag()
    local mouseTime = self:getTimeFromPixels(GUI.mouse.x)
    local mousePitch = self:getPitchFromPixels(GUI.mouse.y)

    local mouseTimeChange = mouseTime - self.prevMouseTime
    local mousePitchChange = mousePitch - self.prevMousePitch

    if self.editNode == nil then
        self:unselectAllCorrectionNodes()

        local mouseOriginalTime = self:getTimeFromPixels(GUI.mouse.ox)
        local mouseOriginalPitch = self:getPitchFromPixels(GUI.mouse.oy)
        --local mouseOriginalSnappedPitch = self:getSnappedPitch(mouseOriginalPitch)

        self.correctionGroup:addNode( {

            time = mouseOriginalTime,
            pitch = mouseOriginalPitch,
            isSelected = false,
            isActive = true

        } )

        self.editNode = self.correctionGroup:addNode( {

            time = mouseTime,
            pitch = mousePitch,
            isSelected = true,
            isActive = false

        } )

    else
        for index, node in ipairs(self.correctionGroup.nodes) do
            if node.isSelected then
                node.time = node.time + mouseTimeChange
                node.pitch = node.pitch + mousePitchChange
            end
        end

        self.correctionGroup:sort()

        for groupIndex, group in ipairs(self.pitchGroups) do
            local editOffset = group.leftTime - self:getTimeLeftBound()

            self.correctionGroup:correctPitchGroup(group, editOffset, pdSettings)
        end

        self:drawPreviewPitchLines()
    end

    self.lWasDragged = true
    self.prevMouseTime = mouseTime
    self.prevMousePitch = mousePitch

    self:drawCorrectionGroup()

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

function GUI.PitchEditor:onupdate()
    self.playCursorCleared = self.playCursorCleared or false

    --self:setItemsToSelectedItems()

    local projectPlaystate = reaper.GetPlayStateEx(0)
    local projectIsPlaying = projectPlaystate & 1 == 1 or projectPlaystate & 4 == 4

    if projectIsPlaying then
        self:drawEditCursor()
        self.playCursorCleared = false

    elseif not self.playCursorCleared then
        self:drawEditCursor()
        self.playCursorCleared = true
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
end

function GUI.PitchEditor:onmousem_up()
    self.shouldZoom = false
    self.shouldDragScroll = false
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

    self:drawKeyBackgrounds()
    self:drawKeyLines()
    self:drawPitchLines()
    self:drawPreviewPitchLines()
    self:drawCorrectionGroup()
    self:drawEditCursor()
    self:drawKeys()

    self:redraw()
end

function GUI.PitchEditor:onresize()
    self.w = GUI.cur_w - 4
    self.h = GUI.cur_h - self.y - 2

    self.keyWidth = self.w * self.keyWidthMult

    self:drawKeyBackgrounds()
    self:drawKeyLines()
    self:drawPitchLines()
    self:drawPreviewPitchLines()
    self:drawCorrectionGroup()
    self:drawEditCursor()
    self:drawKeys()

    self:redraw()
end

function GUI.PitchEditor:ondelete()
    GUI.FreeBuffer(self.backgroundBuff)
    GUI.FreeBuffer(self.keyBackgroundBuff)
    GUI.FreeBuffer(self.keyLinesBuff)
    GUI.FreeBuffer(self.pitchLinesBuff)
    GUI.FreeBuffer(self.previewLinesBuff)
    GUI.FreeBuffer(self.correctionGroupBuff)
    GUI.FreeBuffer(self.editCursorBuff)
    GUI.FreeBuffer(self.keysBuff)
end

function GUI.PitchEditor:ontype()
    local char = GUI.char

    if self.keys[char] then
        self.keys[char](self)
    end

    self:redraw()
end

function GUI.PitchEditor:drawBackground()
    local x, y, w, h = self.x, self.y, self.w, self.h

    self.backgroundBuff = self.backgroundBuff or GUI.GetBuffer()

    gfx.dest = self.backgroundBuff
    gfx.setimgdim(self.backgroundBuff, -1, -1)
    gfx.setimgdim(self.backgroundBuff, w, h)

    GUI.color("elm_bg")
    gfx.rect(0, 0, w, h, 1)

    self:redraw()
end

function GUI.PitchEditor:drawPitchLines()
    if #self.pitchGroups < 1 then return end

    local x, y, w, h = self.x, self.y, self.w, self.h

    local drawThreshold = 2.5 * self.pdSettings.windowStep / self.pdSettings.overlap

    self.pitchLinesBuff = self.pitchLinesBuff or GUI.GetBuffer()

    gfx.dest = self.pitchLinesBuff
    gfx.setimgdim(self.pitchLinesBuff, -1, -1)
    gfx.setimgdim(self.pitchLinesBuff, w, h)

    GUI.color("pitch_lines")

    local groupsTimeOffset = self.pitchGroups[1].leftTime

    for groupIndex, group in ipairs(self.pitchGroups) do
        local previousPoint = nil
        local previousPointX = nil
        local previousPointY = nil

        for pointIndex, point in ipairs(group.points) do
            previousPoint = previousPoint or point

            local pitchValue = point.pitch

            local pointX = self:getPixelsFromTime(group.leftTime + point.time - groupsTimeOffset - group.startOffset) - self.x
            local pointY = self:getPixelsFromPitch(pitchValue) - self.y

            previousPointX = previousPointX or pointX
            previousPointY = previousPointY or pointY

            if point.time - previousPoint.time > drawThreshold then
                previousPointX = pointX
                previousPointY = pointY
            end

            gfx.line(previousPointX, previousPointY, pointX, pointY, false)

            previousPoint = point
            previousPointX = pointX
            previousPointY = pointY
        end
    end

    self:redraw()
end

function GUI.PitchEditor:drawPreviewPitchLines()
    if #self.pitchGroups < 1 then return end

    local drawThreshold = 2.5 * self.pdSettings.windowStep / self.pdSettings.overlap

    self.previewLinesBuff = self.previewLinesBuff or GUI.GetBuffer()

    gfx.dest = self.previewLinesBuff
    gfx.setimgdim(self.previewLinesBuff, -1, -1)
    gfx.setimgdim(self.previewLinesBuff, self.w, self.h)

    GUI.color("pitch_preview_lines")

    local groupsTimeOffset = self.pitchGroups[1].leftTime

    for groupIndex, group in ipairs(self.pitchGroups) do
        local previousPointTime = nil
        local previousPointX = nil
        local previousPointY = nil

        local pitchEnvelope = group.envelope or group:getEnvelope()
        local playrate = group.playrate

        for pointIndex, point in ipairs(group.points) do
            local relativePointTime = point.time - group.startOffset
            previousPointTime = previousPointTime or relativePointTime

            local _, envelopeValue = reaper.Envelope_Evaluate(pitchEnvelope, relativePointTime / playrate, 44100, 0)

            local pitchValue = point.pitch + envelopeValue

            local pointX = self:getPixelsFromTime(group.leftTime + relativePointTime - groupsTimeOffset) - self.x
            local pointY = self:getPixelsFromPitch(pitchValue) - self.y

            previousPointX = previousPointX or pointX
            previousPointY = previousPointY or pointY

            if relativePointTime - previousPointTime > drawThreshold then
                previousPointX = pointX
                previousPointY = pointY
            end

            gfx.line(previousPointX, previousPointY, pointX, pointY, false)

            previousPointTime = relativePointTime
            previousPointX = pointX
            previousPointY = pointY
        end
    end

    self:redraw()
end

function GUI.PitchEditor:drawKeyBackgrounds()
    local x, y, w, h = self.x, self.y, self.w, self.h

    self.keyBackgroundBuff = self.keyBackgroundBuff or GUI.GetBuffer()

    gfx.dest = self.keyBackgroundBuff
    gfx.setimgdim(self.keyBackgroundBuff, -1, -1)
    gfx.setimgdim(self.keyBackgroundBuff, w, h)

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

    self:redraw()
end

function GUI.PitchEditor:drawKeyLines()
    local x, y, w, h = self.x, self.y, self.w, self.h

    local keyHeight = self.zoomY * h * 1.0 / self:getMaxPitch()

    self.keyLinesBuff = self.keyLinesBuff or GUI.GetBuffer()

    gfx.dest = self.keyLinesBuff
    gfx.setimgdim(self.keyLinesBuff, -1, -1)
    gfx.setimgdim(self.keyLinesBuff, w, h)

    if keyHeight > 16 then
        for i = 1, math.floor(self:getMaxPitch()) do
            GUI.color("key_lines")

            local keyLineHeight = self:getPixelsFromPitch(self:getMaxPitch() - i) - y

            gfx.line(0, keyLineHeight, w, keyLineHeight, false)
        end
    end

    self:redraw()
end

function GUI.PitchEditor:drawKeys()
    local x, y, w, h = self.x, self.y, self.w, self.h

    self.keysBuff = self.keysBuff or GUI.GetBuffer()

    gfx.dest = self.keysBuff
    gfx.setimgdim(self.keysBuff, -1, -1)
    gfx.setimgdim(self.keysBuff, w, h)

    local lastKeyEnd = self:getPixelsFromPitch(self:getMaxPitch() + 0.5) - y
    for i = 1, math.floor(self:getMaxPitch()) do
        GUI.color("black_keys")

        for _, value in ipairs(whiteKeys) do
            if i == value then
                GUI.color("white_keys")
            end
        end

        local keyEnd = self:getPixelsFromPitch(self:getMaxPitch() - i + 0.5) - y
        gfx.rect(0, keyEnd, self.keyWidth, keyEnd - lastKeyEnd + 1, 1)

        GUI.color("black_keys")

        gfx.line(0, keyEnd, self.keyWidth - 1, keyEnd, false)

        lastKeyEnd = keyEnd
    end

    self:redraw()
end

function GUI.PitchEditor:drawCorrectionGroup()
    local x, y, w, h = self.x, self.y, self.w, self.h

    self.correctionGroupBuff = self.correctionGroupBuff or GUI.GetBuffer()

    gfx.dest = self.correctionGroupBuff
    gfx.setimgdim(self.correctionGroupBuff, -1, -1)
    gfx.setimgdim(self.correctionGroupBuff, w, h)

    GUI.color("pitch_correction_selected")

    local prevNode = nil

    for index, node in ipairs(self.correctionGroup.nodes) do
        prevNode = prevNode or node

        local leftTimePixels = self:getPixelsFromTime(prevNode.time) - x
        local rightTimePixels = self:getPixelsFromTime(node.time) - x

        local leftPitchPixels = self:getPixelsFromPitch(prevNode.pitch) - y
        local rightPitchPixels = self:getPixelsFromPitch(node.pitch) - y

        if prevNode.isActive then
            gfx.line(leftTimePixels, leftPitchPixels, rightTimePixels, rightPitchPixels, false)
        end

        local circleRadii = 4

        if node.isSelected == true then
            gfx.circle(rightTimePixels, rightPitchPixels, circleRadii, true, false)

        else
            gfx.circle(rightTimePixels, rightPitchPixels, circleRadii, false, false)
        end

        prevNode = node
    end

    self:redraw()
end

function GUI.PitchEditor:drawEditCursor()
    local x, y, w, h = self.x, self.y, self.w, self.h

    local editCursorPosition = reaper.GetCursorPositionEx(0)
    local editCursorPixels = self:getPixelsFromTime(editCursorPosition - self:getTimeLeftBound()) - x

    local playPosition = reaper.GetPlayPositionEx(0)
    local playPositionPixels = self:getPixelsFromTime(playPosition - self:getTimeLeftBound()) - x

    self.editCursorBuff = self.editCursorBuff or GUI.GetBuffer()

    gfx.dest = self.editCursorBuff
    gfx.setimgdim(self.editCursorBuff, -1, -1)
    gfx.setimgdim(self.editCursorBuff, w, h)

    GUI.color("edit_cursor")

    gfx.line(editCursorPixels, 0, editCursorPixels, h, false)

    local projectPlaystate = reaper.GetPlayStateEx(0)
    local projectIsPlaying = projectPlaystate & 1 == 1 or projectPlaystate & 4 == 4
    if projectIsPlaying then
        GUI.color("play_cursor")
        gfx.line(playPositionPixels, 0, playPositionPixels, h, false)
    end

    self:redraw()
end

function GUI.PitchEditor:setItems(items)
    --[[if self.pitchLinesBuff then GUI.FreeBuffer(self.pitchLinesBuff) end
    if self.previewLinesBuff then GUI.FreeBuffer(self.previewLinesBuff) end
    if self.correctionGroupBuff then GUI.FreeBuffer(self.correctionGroupBuff) end

    self.pitchLinesBuff = nil
    self.previewLinesBuff = nil
    self.correctionGroupBuff = nil]]--

    self.pitchGroups = PitchGroup.getPitchGroupsFromItems(items)

    self:drawPitchLines()
    self:drawPreviewPitchLines()
    self:drawCorrectionGroup()

    self:redraw()
end

function GUI.PitchEditor:analyzePitchGroups()
    for groupIndex, group in ipairs(self.pitchGroups) do
        group:analyze(self.pdSettings)
    end

    self:drawPitchLines()
    self:drawPreviewPitchLines()
    self:drawCorrectionGroup()

    self:redraw()
end

function GUI.PitchEditor:getSnappedPitch(pitch)
    return GUI.round(pitch)
end

function GUI.PitchEditor:getTimeFromPixels(xPixels, zoom, scroll)
    local zoom = zoom or self.zoomX
    local scroll = scroll or self.scrollX

    local relativeX = xPixels - self.x - self.keyWidth
    return self:getTimeLength() * (scroll + relativeX / ((self.w - self.keyWidth) * zoom))
end

function GUI.PitchEditor:getPixelsFromTime(time, zoom, scroll)
    local zoom = zoom or self.zoomX
    local scroll = scroll or self.scrollX

    return self.keyWidth + self.x + zoom * (self.w - self.keyWidth) * (time / self:getTimeLength() - scroll)
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

GUI.PitchEditor.keys = {

    [GUI.chars.DELETE] = function(self)

        self:deleteSelectedCorrectionNodes()
        self:drawPreviewPitchLines()
        self:drawCorrectionGroup()
        self:redraw()

    end

}