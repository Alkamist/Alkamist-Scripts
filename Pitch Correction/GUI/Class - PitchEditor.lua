package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

if not GUI then
    reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
    missing_lib = true
    return 0
end


local Lua = require "Various Functions.Lua Functions"
local PitchPoint = require "Pitch Correction.Classes.Class - PitchPoint"
local PitchCorrection = require "Pitch Correction.Classes.Class - PitchCorrection"

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
function GUI.PitchEditor:new(name, z, x, y, w, h, take, pdSettings)
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

    object.zoomX = 1.0
    object.zoomY = 1.0

    object.scrollX = 0.0
    object.scrollY = 0.0

    object.zoomXPreDrag = 1.0
    object.scrollXPreDrag = 0.0

    object.zoomYPreDrag = 1.0
    object.scrollYPreDrag = 1.0

    object.mousePrev = {}
    object.mousePrev.x = 0
    object.mousePrev.y = 0

    object.shouldZoom = false
    object.shouldDragScroll = false

    object.mouse_cap_prev = gfx.mouse_cap

    object.pitchCorrections = {}
    object.selectedPitchCorrections = {}

    object.playCursorCleared = false

    object.lWasDragged = false
    object.previousMouseTime = 0
    object.previousMousePitch = 0
    object.previousSnappedMousePitch = 0

    object.justCreatedNewPitchCorrection = false

    object.editCorrection = nil
    object.editHandle = nil

    object.minimumCorrectionTime = 0.001

    object.keyWidthMult = 0.05
    object.keyWidth = object.w * object.keyWidthMult

    GUI.redraw_z[z] = true

    setmetatable(object, self)
    self.__index = self

    object:setTake(object.take or take, object.pdSettings or pdSettings)

    return object
end

function GUI.PitchEditor:init()
    local x, y, w, h = self.x, self.y, self.w, self.h

    self:drawKeyBackgrounds()
    self:drawBackground()
    self:drawKeyLines()
    self:drawPitchLines()
    self:drawPreviewPitchLines()
    self:drawPitchCorrections()
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

    if self.pitchLinesBuff and self.take then
        gfx.blit(self.pitchLinesBuff, 1, 0, 0, 0, w, h, x, y)
    end

    if self.previewLinesBuff and self.take then
        gfx.blit(self.previewLinesBuff, 1, 0, 0, 0, w, h, x, y)
    end

    if self.pitchCorrectionsBuff then
        gfx.blit(self.pitchCorrectionsBuff, 1, 0, 0, 0, w, h, x, y)
    end

    if self.editCursorBuff and self.take then
        gfx.blit(self.editCursorBuff, 1, 0, 0, 0, w, h, x, y)
    end

    if self.keysBuff then
        gfx.blit(self.keysBuff, 1, 0, 0, 0, w, h, x, y)
    end
end

function GUI.PitchEditor:onmousedown()
    if self.item == nil then return end

    self.zoomXPreDrag = self.zoomX
    self.zoomYPreDrag = self.zoomY
    self.scrollXPreDrag = self.scrollX
    self.scrollYPreDrag = self.scrollY

    local correctionUnderMouse = self:getPitchCorrectionUnderMouse()

    if correctionUnderMouse then
        if gfx.mouse_cap & 8 == 0 and not correctionUnderMouse.isSelected then
            self:unselectAllPitchCorrections()
        end

        self:selectPitchCorrection(correctionUnderMouse)
        self.editCorrection = correctionUnderMouse
        self.editHandle = self:getClosestHandleInPitchCorrectionToMouse(correctionUnderMouse)
    end

    self:drawPreviewPitchLines()
    self:drawPitchCorrections()

    self:redraw()
end

function GUI.PitchEditor:onmouseup()
    if self.item == nil then return end

    if not self.lWasDragged then
        local x, y, w, h = self.x, self.y, self.w, self.h

        local correctionUnderMouse = self:getPitchCorrectionUnderMouse()

        if correctionUnderMouse == nil then
            local playTime = self:getTimeLeftBound() + self:getTimeFromPixels(GUI.mouse.x)
            reaper.SetEditCurPos(playTime, false, true)

            self:drawEditCursor()

            self:unselectAllPitchCorrections()

        -- Not holding shift:
        elseif gfx.mouse_cap & 8 == 0 then
            self:unselectAllPitchCorrections()
            self:selectPitchCorrection(correctionUnderMouse)
        end
    end

    self.lWasDragged = false
    self.justCreatedNewPitchCorrection = false
    self.editCorrection = nil
    self.editHandle = nil

    self:drawPitchCorrections()

    self:redraw()
end

function GUI.PitchEditor:clearEnvelopesUnderPitchCorrection(correction)
    if #self.pitchPoints > 0 then
        local pitchEnvelope = self.pitchPoints[1]:getEnvelope()
        local playrate = self.pitchPoints[1]:getPlayrate()

        reaper.DeleteEnvelopePointRange(pitchEnvelope, playrate * correction:getLeftNode().time, playrate * correction:getRightNode().time)
    end
end

function GUI.PitchEditor:getClosestHandleInPitchCorrectionToMouse(correction)
    if correction == nil then return nil end

    local x, y, w, h = self.x, self.y, self.w, self.h

    local node1X = self:getPixelsFromTime(correction.node1.time)
    local node1Y = self:getPixelsFromPitch(correction.node1.pitch)
    local node2X = self:getPixelsFromTime(correction.node2.time)
    local node2Y = self:getPixelsFromPitch(correction.node2.pitch)

    local mouseDistanceFromNode1 = Lua.distanceBetweenTwoPoints(GUI.mouse.x, GUI.mouse.y, node1X, node1Y)
    local mouseDistanceFromNode2 = Lua.distanceBetweenTwoPoints(GUI.mouse.x, GUI.mouse.y, node2X, node2Y)

    local mouseDistanceFromPitchCorrectionLine = Lua.minDistanceBetweenPointAndLineSegment(GUI.mouse.x, GUI.mouse.y, node1X, node1Y, node2X, node2Y)

    local isNode1 = mouseDistanceFromNode1 - mouseDistanceFromPitchCorrectionLine < mousePitchCorrectionPixelTolerance
    local isNode2 = mouseDistanceFromNode2 - mouseDistanceFromPitchCorrectionLine < mousePitchCorrectionPixelTolerance
    local isLine = isNode1 and isNode2

    if isLine then return "line"
    elseif isNode1 then return "node1"
    elseif isNode2 then return "node2"
    else return "line"end

    return "line"
end

function GUI.PitchEditor:editAndApplyPitchCorrections(corrections)
    if Lua.getTableLength(corrections) < 1 then return end

    local mouseTime = self:getTimeFromPixels(GUI.mouse.x)
    local mousePitch = self:getPitchFromPixels(GUI.mouse.y)

    mouseTime = Lua.clamp(mouseTime,  0.0, self:getTimeLength())
    mousePitch = Lua.clamp(mousePitch,  0.0, self:getMaxPitch())

    local snappedMousePitch = self:getSnappedPitch(mousePitch)

    local mouseTimeChange = mouseTime - self.previousMouseTime
    local mousePitchChange = snappedMousePitch - self.previousSnappedMousePitch

    local leftMostNode = nil
    local rightMostNode = nil
    local bottomMostNode = nil
    local topMostNode = nil

    for key, correction in pairs(corrections) do
        self:clearEnvelopesUnderPitchCorrection(correction)

        leftMostNode = leftMostNode or correction:getLeftNode()
        rightMostNode = rightMostNode or correction:getRightNode()
        bottomMostNode = bottomMostNode or leftMostNode
        topMostNode = topMostNode or rightMostNode

        if correction.node1.time < leftMostNode.time then leftMostNode = correction.node1 end
        if correction.node2.time < leftMostNode.time then leftMostNode = correction.node2 end

        if correction.node1.time > rightMostNode.time then rightMostNode = correction.node1 end
        if correction.node2.time > rightMostNode.time then rightMostNode = correction.node2 end

        if correction.node1.pitch < bottomMostNode.pitch then bottomMostNode = correction.node1 end
        if correction.node2.pitch < bottomMostNode.pitch then bottomMostNode = correction.node2 end

        if correction.node1.pitch > topMostNode.pitch then topMostNode = correction.node1 end
        if correction.node2.pitch > topMostNode.pitch then topMostNode = correction.node2 end
    end

    mouseTimeChange = Lua.clamp(mouseTimeChange,  -leftMostNode.time, self:getTimeLength() - rightMostNode.time)
    mousePitchChange = Lua.clamp(mousePitchChange, -bottomMostNode.pitch, self:getMaxPitch() - topMostNode.pitch)

    for key, correction in PitchCorrection.pairs(corrections) do
        if self.justCreatedNewPitchCorrection then
            correction.node2.time = correction.node2.time + mouseTimeChange
            correction.node2.pitch = correction.node2.pitch + mousePitchChange

        else

            if self.editHandle == "node1" or self.editHandle == "line" then
                correction.node1.time = correction.node1.time + mouseTimeChange
                correction.node1.pitch = correction.node1.pitch + mousePitchChange
            end

            if self.editHandle == "node2" or self.editHandle == "line" then
                correction.node2.time = correction.node2.time + mouseTimeChange
                correction.node2.pitch = correction.node2.pitch + mousePitchChange
            end

        end

        self:applyPitchCorrection(correction)
    end

    self.previousMouseTime = mouseTime
    self.previousMousePitch = mousePitch
    self.previousSnappedMousePitch = snappedMousePitch
end

function GUI.PitchEditor:createAndEditNewPitchCorrection(leftTime, rightTime, leftPitch, rightPitch)
    self:unselectAllPitchCorrections()

    local newCorrection = PitchCorrection:new(leftTime, rightTime, leftPitch, rightPitch)
    self:selectPitchCorrection(newCorrection)
    table.insert(self.pitchCorrections, newCorrection)

    self.justCreatedNewPitchCorrection = true
    self.editCorrection = newCorrection

    return newCorrection
end

function GUI.PitchEditor:handleCorrectionEditing()
    -- The drag just started.
    if not self.lWasDragged then
        local mouseOriginalTime = self:getTimeFromPixels(GUI.mouse.ox, self.zoomXPreDrag, self.scrollXPreDrag)
        local mouseOriginalPitch = self:getPitchFromPixels(GUI.mouse.oy, self.zoomYPreDrag, self.scrollYPreDrag)
        local mouseOriginalSnappedPitch = self:getSnappedPitch(mouseOriginalPitch)

        self.previousMouseTime = mouseOriginalTime
        self.previousMousePitch = mouseOriginalPitch
        self.previousSnappedMousePitch = self:getSnappedPitch(mouseOriginalPitch)

        if self.editCorrection == nil then
            self:createAndEditNewPitchCorrection(mouseOriginalTime, mouseOriginalTime, mouseOriginalSnappedPitch, mouseOriginalSnappedPitch)
        end
    end

    if self.editCorrection then
        self:editAndApplyPitchCorrections(self.selectedPitchCorrections, mouseTime, mousePitch, snappedMousePitch)

        PitchCorrection.updateLinkedOrder(self.pitchCorrections)

        self:drawPreviewPitchLines()
    end

    self:drawPitchCorrections()
end

function GUI.PitchEditor:ondrag()
    if self.item == nil then return end

    self:handleCorrectionEditing()

    self.lWasDragged = true

    self:redraw()
end

function GUI.PitchEditor:onupdate()
    local selectedItem = reaper.GetSelectedMediaItem(0, 0)

    if selectedItem ~= previousSelectedItem then
        local selectedTake = nil

        if selectedItem then selectedTake = reaper.GetActiveTake(selectedItem) end

        self:setTake(selectedTake, self.pdSettings)
    end



    local projectPlaystate = reaper.GetPlayStateEx(0)
    local projectIsPlaying = projectPlaystate & 1 == 1 or projectPlaystate & 4 == 4

    if projectIsPlaying then
        self:drawEditCursor()
        self.playCursorCleared = false
    elseif not self.playCursorCleared then
        self:drawEditCursor()
        self.playCursorCleared = true
    end

    previousSelectedItem = selectedItem
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
    self:drawPitchCorrections()
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
    self:drawPitchCorrections()
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
    GUI.FreeBuffer(self.pitchCorrectionsBuff)
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
    if #self.pitchPoints < 1 then return end
    if self.take == nil then return end

    local x, y, w, h = self.x, self.y, self.w, self.h

    local windowStep = 0.04
    local overlap = 2
    local drawThreshold = 2.5 * windowStep / overlap

    self.pitchLinesBuff = self.pitchLinesBuff or GUI.GetBuffer()

    gfx.dest = self.pitchLinesBuff
    gfx.setimgdim(self.pitchLinesBuff, -1, -1)
    gfx.setimgdim(self.pitchLinesBuff, w, h)

    GUI.color("pitch_lines")

    local previousPoint = nil
    local previousPointX = 0
    local previousPointY = 0

    for pointKey, point in PitchPoint.pairs(self.pitchPoints) do
        local pointX = self:getPixelsFromTime(point.time) - x
        local pointY = self:getPixelsFromPitch(point.pitch) - y

        if pointKey == 1 then
            previousPoint = point
            previousPointX = pointX
            previousPointY = pointY
        end

        if point.time - previousPoint.time > drawThreshold then
            previousPointX = pointX
            previousPointY = pointY
        end

        gfx.line(previousPointX, previousPointY, pointX, pointY, false)

        previousPoint = point
        previousPointX = pointX
        previousPointY = pointY
    end

    self:redraw()
end

function GUI.PitchEditor:drawPreviewPitchLines()
    if #self.pitchPoints < 1 then return end
    if self.take == nil then return end

    local x, y, w, h = self.x, self.y, self.w, self.h

    local windowStep = 0.04
    local overlap = 2
    local drawThreshold = 2.5 * windowStep / overlap

    self.previewLinesBuff = self.previewLinesBuff or GUI.GetBuffer()

    gfx.dest = self.previewLinesBuff
    gfx.setimgdim(self.previewLinesBuff, -1, -1)
    gfx.setimgdim(self.previewLinesBuff, w, h)

    GUI.color("pitch_preview_lines")

    local previousPoint = nil
    local previousPointX = 0
    local previousPointY = 0

    local pitchEnvelope = self.pitchPoints[1]:getEnvelope()

    for pointKey, point in PitchPoint.pairs(self.pitchPoints) do
        local _, envelopeValue = reaper.Envelope_Evaluate(pitchEnvelope, point.time, 44100, 0)

        local pitchValue = point.pitch + envelopeValue

        local pointX = self:getPixelsFromTime(point.time) - x
        local pointY = self:getPixelsFromPitch(pitchValue) - y

        if pointKey == 1 then
            previousPoint = point
            previousPointX = pointX
            previousPointY = pointY
        end

        if point.time - previousPoint.time > drawThreshold then
            previousPointX = pointX
            previousPointY = pointY
        end

        gfx.line(previousPointX, previousPointY, pointX, pointY, false)

        previousPoint = point
        previousPointX = pointX
        previousPointY = pointY
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

function GUI.PitchEditor:drawPitchCorrections()
    local x, y, w, h = self.x, self.y, self.w, self.h

    self.pitchCorrectionsBuff = self.pitchCorrectionsBuff or GUI.GetBuffer()

    gfx.dest = self.pitchCorrectionsBuff
    gfx.setimgdim(self.pitchCorrectionsBuff, -1, -1)
    gfx.setimgdim(self.pitchCorrectionsBuff, w, h)

    for key, correction in PitchCorrection.pairs(self.pitchCorrections) do
        local leftTimePixels = self:getPixelsFromTime(correction:getLeftNode().time) - x
        local rightTimePixels = self:getPixelsFromTime(correction:getRightNode().time) - x

        local leftPitchPixels = self:getPixelsFromPitch(correction:getLeftNode().pitch) - y
        local rightPitchPixels = self:getPixelsFromPitch(correction:getRightNode().pitch) - y

        local circleRadii = 3

        if correction.isSelected == true then
            GUI.color("pitch_correction_selected")
            gfx.line(leftTimePixels, leftPitchPixels, rightTimePixels, rightPitchPixels, false)

            gfx.circle(leftTimePixels, leftPitchPixels, circleRadii, true, false)
            gfx.circle(rightTimePixels, rightPitchPixels, circleRadii, true, false)
        else
            GUI.color("pitch_correction")
            gfx.line(leftTimePixels, leftPitchPixels, rightTimePixels, rightPitchPixels, false)

            gfx.circle(leftTimePixels, leftPitchPixels, circleRadii, true, false)
            gfx.circle(rightTimePixels, rightPitchPixels, circleRadii, true, false)
        end
    end

    self:redraw()
end

function GUI.PitchEditor:drawEditCursor()
    if self.item == nil then return end

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

function GUI.PitchEditor:setTake(take, pdSettings)
    local isTake = reaper.ValidatePtr(take, "MediaItem_Take*")

    if self.pitchLinesBuff then GUI.FreeBuffer(self.pitchLinesBuff) end
    if self.previewLinesBuff then GUI.FreeBuffer(self.previewLinesBuff) end
    if self.pitchCorrectionsBuff then GUI.FreeBuffer(self.pitchCorrectionsBuff) end

    self.pitchLinesBuff = nil
    self.previewLinesBuff = nil
    self.pitchCorrectionsBuff = nil

    if take and isTake then
        self.take = take
        self.item = reaper.GetMediaItemTake_Item(take)
        self.takeGUID = reaper.BR_GetMediaItemTakeGUID(take)
        self.pitchPoints = PitchPoint.getPitchPoints(self.takeGUID)
        self.pdSettings = pdSettings
    else
        self.take = nil
        self.item = nil
        self.takeGUID = nil

        for key in pairs(self.pitchPoints) do
            self.pitchPoints[key] = nil
        end

        for key in pairs(self.pitchCorrections) do
            self.pitchCorrections[key] = nil
        end

        for key in pairs(self.pitchCorrections) do
            self.pdSettings[key] = nil
        end
    end

    self:drawPitchLines()
    self:drawPreviewPitchLines()
    self:drawPitchCorrections()

    self:redraw()
end

function GUI.PitchEditor:getSnappedPitch(pitch)
    return GUI.round(pitch)
end

function GUI.PitchEditor:getTimeFromPixels(xPixels, zoom, scroll)
    local x, y, w, h = self.x, self.y, self.w, self.h
    local zoom = zoom or self.zoomX
    local scroll = scroll or self.scrollX

    local relativeX = xPixels - x - self.keyWidth
    return self:getTimeLength() * (scroll + relativeX / ((w - self.keyWidth) * zoom))
end

function GUI.PitchEditor:getPixelsFromTime(time, zoom, scroll)
    local x, y, w, h = self.x, self.y, self.w, self.h
    local zoom = zoom or self.zoomX
    local scroll = scroll or self.scrollX

    return self.keyWidth + x + zoom * (w - self.keyWidth) * (time / self:getTimeLength() - scroll)
end

function GUI.PitchEditor:getPitchFromPixels(yPixels, zoom, scroll)
    local x, y, w, h = self.x, self.y, self.w, self.h
    local zoom = zoom or self.zoomY
    local scroll = scroll or self.scrollY

    local relativeY = yPixels - y
    return self:getMaxPitch() * (1.0 - (scroll + relativeY / (h * zoom))) - 0.5
end

function GUI.PitchEditor:getPixelsFromPitch(pitch, zoom, scroll)
    local x, y, w, h = self.x, self.y, self.w, self.h
    local zoom = zoom or self.zoomY
    local scroll = scroll or self.scrollY

    local pitchRatio = 1.0 - (0.5 + pitch) / self:getMaxPitch()
    return y + zoom * h * (pitchRatio - scroll)
end

function GUI.PitchEditor:getTimeLeftBound()
    if reaper.ValidatePtr(self.item, "MediaItem*") then
        return reaper.GetMediaItemInfo_Value(self.item, "D_POSITION")
    end

    return 0
end

function GUI.PitchEditor:getTimeLength()
    if reaper.ValidatePtr(self.item, "MediaItem*") then
        return reaper.GetMediaItemInfo_Value(self.item, "D_LENGTH")
    end

    return 0
end

function GUI.PitchEditor:getMaxPitch()
    return 128.0
end

function GUI.PitchEditor:getMouseDistanceToPitchCorrection(correction)
    if correction == nil then return nil end

    local x, y, w, h = self.x, self.y, self.w, self.h

    local leftHandleX = self:getPixelsFromTime(correction:getLeftNode().time)
    local leftHandleY = self:getPixelsFromPitch(correction:getLeftNode().pitch)
    local rightHandleX = self:getPixelsFromTime(correction:getRightNode().time)
    local rightHandleY = self:getPixelsFromPitch(correction:getRightNode().pitch)

    local mouseDistanceFromPitchCorrectionLine = Lua.minDistanceBetweenPointAndLineSegment(GUI.mouse.x, GUI.mouse.y, leftHandleX, leftHandleY, rightHandleX, rightHandleY)

    return mouseDistanceFromPitchCorrectionLine
end

function GUI.PitchEditor:getPitchCorrectionUnderMouse()
    local x, y, w, h = self.x, self.y, self.w, self.h

    local mouseTime = self:getTimeFromPixels(GUI.mouse.x) or 0
    local mousePitch = self:getPitchFromPixels(GUI.mouse.y) or 0

    local correctionDistances = {}

    for key, correction in PitchCorrection.pairs(self.pitchCorrections) do
        correctionDistances[key] = self:getMouseDistanceToPitchCorrection(correction)
    end

    local smallestDistanceKey = nil
    for key, distance in pairs(correctionDistances) do
        if smallestDistanceKey == nil then
            smallestDistanceKey = key
        end

        if distance < correctionDistances[smallestDistanceKey] then
            smallestDistanceKey = key
        end
    end

    if smallestDistanceKey == nil then return nil end

    if correctionDistances[smallestDistanceKey] <= mousePitchCorrectionPixelTolerance then
        return self.pitchCorrections[smallestDistanceKey]
    end

    return nil
end

function GUI.PitchEditor:selectPitchCorrection(correction)
    if not correction.isSelected then
        correction.isSelected = true
        table.insert(self.selectedPitchCorrections, correction)
    end
end

function GUI.PitchEditor:unselectAllPitchCorrections()
    Lua.arrayRemove(self.selectedPitchCorrections, function(t, i)
        t[i].isSelected = false
        return true
    end)
end

function GUI.PitchEditor:deleteSelectedPitchCorrections()
    Lua.arrayRemove(self.pitchCorrections, function(t, i)
        local value = t[i]

        if value.isSelected then
            self:clearEnvelopesUnderPitchCorrection(value)
        end

        return value.isSelected
    end)

    self:unselectAllPitchCorrections()

    reaper.UpdateArrange()
end

function GUI.PitchEditor:getClosestValidTimeToPosition(time)
    local closestTime = nil
    local insideCorrection = nil

    for key, correction in PitchCorrection.pairs(self.pitchCorrections) do
        if correction ~= self.editCorrection then
            if correction:timeIsInside(time) then
                insideCorrection = correction
            end
        end
    end

    if insideCorrection then
        local timeToLeft = math.abs(time - insideCorrection:getLeftNode().time)
        local timeToRight = math.abs(time - insideCorrection:getRightNode().time)

        if timeToLeft < timeToRight then
            closestTime = insideCorrection:getLeftNode().time
        else
            closestTime = insideCorrection:getRightNode().time
        end
    else
        closestTime = time
    end

    return closestTime
end

function GUI.PitchEditor:applyPitchCorrection(correction)
    if self.take and #self.pitchPoints > 0 then
        PitchCorrection.correctPitchPoints(self.pitchPoints, correction, self.pdSettings)

        reaper.UpdateArrange()
    end
end

GUI.PitchEditor.keys = {

    [GUI.chars.DELETE] = function(self)

        self:deleteSelectedPitchCorrections()
        self:drawPreviewPitchLines()
        self:drawPitchCorrections()
        self:redraw()

    end

}