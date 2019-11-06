local reaper = reaper
local gfx = gfx
local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Class = require("Class")
local ViewAxis = require("GFX.ViewAxis")
local BoxSelect = require("GFX.BoxSelect")
local PitchCorrectedTake = require("Pitch Correction.PitchCorrectedTake")

--==============================================================
--== Helpful Functions =========================================
--==============================================================

local function pointIsSelected(point)
    return point.isSelected
end
local function setPointSelected(point, shouldSelect)
    point.isSelected = shouldSelect
end
local function getWhiteKeyNumbers()
    local whiteKeyMultiples = {1, 3, 4, 6, 8, 9, 11}
    local whiteKeys = {}
    for i = 1, 11 do
        for _, value in ipairs(whiteKeyMultiples) do
            table.insert(whiteKeys, (i - 1) * 12 + value)
        end
    end
    return whiteKeys
end
local function arrayRemove(t, fn)
    local n = #t
    local j = 1
    for i = 1, n do
        if not fn(i, j) then
            if i ~= j then
                t[j] = t[i]
                t[i] = nil
            end
            j = j + 1
        else
            t[i] = nil
        end
    end
    return t
end
local function round(number, places)
    if not places then
        return number > 0 and math.floor(number + 0.5) or math.ceil(number - 0.5)
    else
        places = 10 ^ places
        return number > 0 and math.floor(number * places + 0.5)
                          or math.ceil(number * places - 0.5) / places
    end
end

--==============================================================
--== Initialization ============================================
--==============================================================

local PitchEditor = {
    x = 0,
    y = 0,
    w = 0,
    h = 0,
    whiteKeyNumbers = getWhiteKeyNumbers(),
    minKeyHeightToDrawCenterline = 16,
    pitchHeight = 128,
    backgroundColor = { 0.22, 0.22, 0.22, 1.0, 0 },
    blackKeyColor = { 0.22, 0.22, 0.22, 1.0, 0 },
    whiteKeyColor = { 0.29, 0.29, 0.29, 1.0, 0 },
    keyCenterLineColor = { 1.0, 1.0, 1.0, 0.09, 1 },
    edgeColor = { 1.0, 1.0, 1.0, -0.1, 1 },
    edgeShade = { 1.0, 1.0, 1.0, -0.04, 1 },
    editCursorColor = { 1.0, 1.0, 1.0, 0.34, 1 },
    playCursorColor = { 1.0, 1.0, 1.0, 0.2, 1 },
    pitchCorrectionActiveColor = { 0.3, 0.6, 0.9, 1.0, 0 },
    pitchCorrectionInactiveColor = { 0.9, 0.3, 0.3, 1.0, 0 },
    peakColor = { 1.0,   1.0,  1.0,  1.0,  0 },
    correctedPitchLineColor = { 0.3, 0.7, 0.3, 1.0, 0 },
    pitchLineColor = { 0.1, 0.3, 0.1, 1.0, 0 },
    pitchCorrectionEditPixelRange = 7,
    scaleWithWindow = true,
    mouseTime = 0.0,
    mouseTimeOnLeftDown = 0.0,
    previousMouseTime = 0.0,
    mouseTimeChange = 0.0,
    mousePitch = 0.0,
    mousePitchOnLeftDown = 0.0,
    previousMousePitch = 0.0,
    mousePitchChange = 0.0,
    snappedMousePitch = 0.0,
    previousSnappedMousePitch = 0.0,
    snappedMousePitchChange = 0.0,
    altKeyWasDownOnPointEdit = false,
    fixErrorMode =  false,
    enablePitchCorrections = true,
    view = {
        x = ViewAxis:new(),
        y = ViewAxis:new()
    },
    track = nil,
    take = PitchCorrectedTake:new(),
    --boxSelect = BoxSelect:new{
    --    parent = self,
    --    thingsToSelect = self.take.corrections
    --}
    --self.elements = {
    --    [1] = self.boxSelect
    --}
}
function PitchEditor:new(input)
    return Class:new({ PitchEditor }, input)
end

--==============================================================
--== Pitch Correction Points ===================================
--==============================================================

function PitchEditor:insertPitchCorrectionPoint(point)
    if not self.enablePitchCorrections then return end
    self.take:insertPitchCorrectionPoint{
        x =          self:timeToPixels(point.time),
        y =          self:pitchToPixels(point.pitch),
        time =       point.time,
        pitch =      point.pitch,
        isSelected = point.isSelected,
        isActive =   point.isActive
    }
end
function PitchEditor:handlePitchCorrectionPointLeftDown(mouse)
    if not self.enablePitchCorrections then return end

    self.altKeyWasDownOnPointEdit = false

    if self.mouseOverPitchCorrectionIndex then
        local point = self.take.corrections.points[self.mouseOverPitchCorrectionIndex]
        local nextPoint = self.take.corrections.points[self.mouseOverPitchCorrectionIndex + 1]
        self.pitchCorrectionEditPoint = point

        local pointWasAlreadySelected = point.isSelected
        if not pointWasAlreadySelected then
            if not self.keyboard.modifiers.shift:isPressed() then
                self:unselectAllPitchCorrectionPoints()
            end
            point.isSelected = true
        end

        if self.keyboard.modifiers.alt:isPressed() then
            self.altKeyWasDownOnPointEdit = true
            local corrections = self.take.corrections.points
            for i = 1, #corrections do
                local correction = corrections[i]
                if correction.isSelected then
                    correction.isActive = not correction.isActive
                end
            end
            self.take:correctAllPitchPoints()
        end

        if not self.mouseIsOverPoint then
            if nextPoint then nextPoint.isSelected = true end
        end
    end
end
function PitchEditor:handlePitchCorrectionPointLeftDrag(mouse)
    if not self.enablePitchCorrections then return end
    local mousePitch = self.snappedMousePitch
    local mousePitchChange = self.snappedMousePitchChange
    local mousePitchOnLeftDown = self.snappedMousePitchOnLeftDown

    if self.keyboard.modifiers.shift:isPressed() then
        mousePitch = self.mousePitch
        mousePitchChange = self.mousePitchChange
        mousePitchOnLeftDown = self.mousePitchOnLeftDown
    end

    if not self.pitchCorrectionEditPoint and mouse.buttons.left:justStartedDragging(self) then
        self:unselectAllPitchCorrectionPoints()

        self:insertPitchCorrectionPoint{
            time = self.mouseTimeOnLeftDown,
            pitch = mousePitchOnLeftDown,
            isActive = true,
            isSelected = false
        }
        local firstPointIndex = self.take.corrections.mostRecentInsertedIndex

        local previousPoint = self.take.corrections.points[firstPointIndex - 1]
        if previousPoint and self.keyboard.modifiers.alt:isPressed() then previousPoint.isActive = true end

        self:insertPitchCorrectionPoint{
            time = self.mouseTime,
            pitch = mousePitch,
            isActive = false,
            isSelected = true
        }
        local newPointIndex = self.take.corrections.mostRecentInsertedIndex
        self.newPitchCorrectionPoint = self.take.corrections.points[newPointIndex]
    elseif not self.altKeyWasDownOnPointEdit then
        local corrections = self.take.corrections.points
        for i = 1, #corrections do
            local correction = corrections[i]
            if correction.isSelected then
                correction.time = correction.time + self.mouseTimeChange
                correction.pitch = correction.pitch + mousePitchChange
                correction.x = self:timeToPixels(correction.time)
                correction.y = self:pitchToPixels(correction.pitch)
            end
        end
        self.take.corrections:sortPoints()
        self.take:correctAllPitchPoints()
    end
end
function PitchEditor:handlePitchCorrectionPointLeftUp(mouse)
    if not self.enablePitchCorrections then return end
    if self.newPitchCorrectionPoint then
        self.newPitchCorrectionPoint.isSelected = false
    end

    self.newPitchCorrectionPoint = nil
    self.pitchCorrectionEditPoint = nil
end
function PitchEditor:handlePitchCorrectionPointLeftDoubleClick(mouse)
    if not self.enablePitchCorrections then return end
    if self.mouseOverPitchCorrectionIndex and not self.newPitchCorrectionPoint then
        self:snapSelectedPitchCorrectionsToNearestPitch()
        self.take:correctAllPitchPoints()
    end
end
function PitchEditor:recalculatePitchCorrectionCoordinates()
    if not self.enablePitchCorrections then return end
    local corrections = self.take.corrections.points
    for i = 1, #corrections do
        local correction = corrections[i]
        correction.x = self:timeToPixels(correction.time)
        correction.y = self:pitchToPixels(correction.pitch)
    end
end
function PitchEditor:updatePitchCorrectionMouseOver()
    if not self.enablePitchCorrections then return end
    local index, indexIsPoint = self.take.corrections:getIndexOfPointOrSegmentClosestToPointWithinDistance(self.relativeMouseX, self.relativeMouseY, self.pitchCorrectionEditPixelRange)

    if index then
        local points = self.take.corrections.points
        if not indexIsPoint and not points[index].isActive then
            index = nil
            indexIsPoint = nil
        end
        self.mouseOverPitchCorrectionIndex = index
        self.mouseIsOverPoint = indexIsPoint
    else
        self.mouseOverPitchCorrectionIndex = nil
        self.mouseIsOverPoint = nil
    end
end
function PitchEditor:unselectAllPitchCorrectionPoints()
    if not self.enablePitchCorrections then return end
    local corrections = self.take.corrections.points
    for i = 1, #corrections do
        local correction = corrections[i]
        correction.isSelected = false
    end
end
function PitchEditor:snapSelectedPitchCorrectionsToNearestPitch()
    if not self.enablePitchCorrections then return end
    local corrections = self.take.corrections.points
    for i = 1, #corrections do
        local correction = corrections[i]
        correction.pitch = round(correction.pitch)
    end
end
function PitchEditor:deleteSelectedPitchCorrectionPoints()
    if not self.enablePitchCorrections then return end
    arrayRemove(self.take.corrections.points, function(index)
        return self.take.corrections.points[index].isSelected
    end)
    self.take:correctAllPitchPoints()
end

--==============================================================
--== Item Pitches ==============================================
--==============================================================

function PitchEditor:analyzeTakePitches(settings)
    self.take:prepareToAnalyzePitch(settings)
end
function PitchEditor:recalculateTakePitchCoordinates()
    local points = self.take.pitches.points
    for i = 1, #points do
        local point = points[i]
        point.x = self:timeToPixels(point.time)
        point.y = self:pitchToPixels(point.pitch)
    end
end
function PitchEditor:setFixErrorMode(state)
    self.fixErrorMode = state
    self.enablePitchCorrections = not self.fixErrorMode
    if self.enablePitchCorrections then
        self:recalculatePitchCorrectionCoordinates()
    end
end

--==============================================================
--== Drawing Code ==============================================
--==============================================================

function PitchEditor:drawMainBackground()
    self:setColor(self.backgroundColor)
    self:drawRectangle(0, 0, self.w, self.h, true)
end
function PitchEditor:drawKeyBackgrounds()
    local previousKeyEnd = self:pitchToPixels(self.pitchHeight + 0.5)

    for i = 1, self.pitchHeight do
        local keyEnd = self:pitchToPixels(self.pitchHeight - i + 0.5)
        local keyHeight = keyEnd - previousKeyEnd

        self:setColor(self.blackKeyColor)
        for _, value in ipairs(self.whiteKeyNumbers) do
            if i == value then
                self:setColor(self.whiteKeyColor)
            end
        end
        self:drawRectangle(0, keyEnd, self.w, keyHeight + 1, true)

        self:setColor(self.blackKeyColor)
        self:drawLine(0, keyEnd, self.w - 1, keyEnd, false)

        if keyHeight > self.minKeyHeightToDrawCenterline then
            local keyCenterLine = self:pitchToPixels(self.pitchHeight - i)

            self:setColor(self.keyCenterLineColor)
            self:drawLine(0, keyCenterLine, self.w - 1, keyCenterLine, false)
        end

        previousKeyEnd = keyEnd
    end
end
function PitchEditor:drawTakePitchLines()
    local pitches = self.take.pitches.points
    local envelope = self.take.envelope
    local playrate = self.take.playrate

    local previousPoint
    local previousPointCorrectedY
    for i = 1, #pitches do
        local point =     pitches[i]
        local nextPoint = pitches[i + 1]

        local _, envelopeValue = reaper.Envelope_Evaluate(envelope, point.time * playrate, 44100, 0)
        local correctedPointY = self:pitchToPixels(point.pitch + envelopeValue)

        if previousPoint then
            if point.time - previousPoint.time <= 0.1 then
                if self.fixErrorMode then
                    self:setColor(self.correctedPitchLineColor)
                    self:drawLine(previousPoint.x, previousPoint.y, point.x, point.y, true)
                else
                    self:setColor(self.pitchLineColor)
                    self:drawLine(previousPoint.x, previousPoint.y, point.x, point.y, true)
                    self:setColor(self.correctedPitchLineColor)
                    self:drawLine(previousPoint.x, previousPointCorrectedY, point.x, correctedPointY, true)
                end
            end

            self:setColor(self.correctedPitchLineColor)
            if self.fixErrorMode then
                self:drawRectangle(previousPoint.x - 1, previousPoint.y - 1, 3, 3, true)
            else
                self:drawRectangle(previousPoint.x - 1, previousPointCorrectedY - 1, 3, 3, true)
            end
        end

        if nextPoint == nil then
            self:setColor(self.correctedPitchLineColor)
            if self.fixErrorMode then
                self:drawRectangle(point.x - 1, point.y - 1, 3, 3, true)
            else
                self:drawRectangle(point.x - 1, correctedPointY - 1, 3, 3, true)
            end
        end

        previousPoint = point
        previousPointCorrectedY = correctedPointY
    end
end
--[[function PitchEditor:drawPeaks()
    self:setColor(self.peakColor)

    local x =                round( math.max(self:timeToPixels(0.0), 0) )
    local y =                round( self.h * 0.5 )
    local rawW =             self:timeToPixels(self.take.length) - x
    local w =                round( math.max(math.min(rawW, self.w - x), 1) )
    local h =                200
    local startTime =        math.min(math.max(self:pixelsToTime(0), 0.0), self.take.length)
    local startTimeSamples = math.max(math.min(math.floor(startTime * self.take.sampleRate * 0.5), self.numberOfPeaks), 1)
    local timeLength =       math.max(math.min(self:pixelsToTime(self.w), self.take.length) - startTime, 0.0)

    local peakSkip = math.max(self.numberOfPeaks - startTimeSamples, 1) / w

    for i = round(startTimeSamples / peakSkip), w - 1 do
        local index = math.max(round(i * peakSkip), 1)

        local peakMax = self.peaks[index]
        local peakMin = self.peaks[self.numberOfPeaks + index]

        --if peakRate < sampleRate then
            local drawX = x + i
            local drawY1 = y - peakMax * h
            local drawY2 = y - peakMin * h
            self:drawLine(drawX, drawY1, drawX, drawY2, true)
        --else
        --    local drawX = x + (i - 1) * sampleSpacing
        --    local waveHeight = peakMax * h
        --    local drawY = y - math.max(waveHeight, 0)
        --    local drawW = math.max(sampleSpacing - 1, 1)
        --    local drawH = math.abs(waveHeight)
        --    self:drawRectangle(drawX, drawY, drawW, drawH, true)
        --end
    end
end]]--
function PitchEditor:drawEdges()
    self:setColor(self.edgeColor)
    local leftEdgePixels =  self:timeToPixels(0.0)
    local rightEdgePixels = self:timeToPixels(self.take.length)
    self:drawLine(leftEdgePixels, 0, leftEdgePixels, self.h, false)
    self:drawLine(rightEdgePixels, 0, rightEdgePixels, self.h, false)

    self:setColor(self.edgeShade)
    self:drawRectangle(0, 0, leftEdgePixels, self.h, true)
    local rightShadeStart = rightEdgePixels + 1
    self:drawRectangle(rightShadeStart, 0, self.w - rightShadeStart, self.h, true)
end
function PitchEditor:drawEditCursor()
    local editCursorPixels =   self:timeToPixels(reaper.GetCursorPosition() - self.take.leftTime)
    local playPositionPixels = self:timeToPixels(reaper.GetPlayPosition() - self.take.leftTime)

    self:setColor(self.editCursorColor)
    self:drawLine(editCursorPixels, 0, editCursorPixels, self.h, false)

    local playState = reaper.GetPlayState()
    local projectIsPlaying = playState & 1 == 1
    local projectIsRecording = playState & 4 == 4
    if projectIsPlaying or projectIsRecording then
        self:setColor(self.playCursorColor)
        self:drawLine(playPositionPixels, 0, playPositionPixels, self.h, false)
    end
end
function PitchEditor:drawPitchCorrectionSegment(i, group)
    local point =     group[i]
    local nextPoint = group[i + 1]
    if nextPoint == nil then return end
    local mouseIsOverSegment = i == self.mouseOverPitchCorrectionIndex and (not self.mouseIsOverPoint)

    self:setColor(self.pitchCorrectionActiveColor)

    if point.isActive then
        self:drawLine(point.x, point.y, nextPoint.x, nextPoint.y, true)
    end

    if mouseIsOverSegment and point.isActive and not self.newPitchCorrectionPoint and not self.pitchCorrectionEditPoint then
        self:setColor{1.0, 1.0, 1.0, 0.4, 1}
        self:drawLine(point.x, point.y, nextPoint.x, nextPoint.y, true)
    end
end
function PitchEditor:drawPitchCorrectionPoint(i, group)
    local point = group[i]
    local mouseIsOverThisPoint = i == self.mouseOverPitchCorrectionIndex and self.mouseIsOverPoint

    if point.isActive then
        self:setColor(self.pitchCorrectionActiveColor)
    else
        self:setColor(self.pitchCorrectionInactiveColor)
    end

    self:drawCircle(point.x, point.y, 3, true, true)

    if point.isSelected then
        self:setColor{1.0, 1.0, 1.0, 0.3, 1}
        self:drawCircle(point.x, point.y, 3, true, true)
    end

    if mouseIsOverThisPoint and not self.newPitchCorrectionPoint and not self.pitchCorrectionEditPoint then
        self:setColor{1.0, 1.0, 1.0, 0.3, 1}
        self:drawCircle(point.x, point.y, 3, true, true)
    end
end
function PitchEditor:drawPitchCorrections()
    if self.enablePitchCorrections then
        self:setColor(self.pitchCorrectionActiveColor)

        local corrections = self.take.corrections.points
        for i = 1, #corrections do
            if i == 1 then self:drawPitchCorrectionSegment(1, corrections) end
            self:drawPitchCorrectionSegment(i + 1, corrections)
            self:drawPitchCorrectionPoint(i, corrections)
        end
    end
end

--==============================================================
--== Editor Specific Functions =================================
--==============================================================

function PitchEditor:projectHasChanged()
    local projectChangeCount = reaper.GetProjectStateChangeCount(0)
    if projectChangeCount ~= self.previousProjectChangeCount then
        self.previousProjectChangeCount = projectChangeCount
        return true
    end
end
--[[function PitchEditor:updatePeaks()
    local numberOfSamples = math.floor(self.take.sampleRate * self.take.length)
    local numberOfChannels = 1
    --local wantExtraType = 115  -- 's' char to get spectral information
    local wantExtraType = 0

    self.peaks = reaper.new_array(numberOfSamples * numberOfChannels * 3)
    self.peaks.clear()
    local value = reaper.GetMediaItemTake_Peaks(self.take.pointer,
                                                self.take.sampleRate / 2,
                                                self.take.leftTime,
                                                numberOfChannels,
                                                numberOfSamples,
                                                wantExtraType,
                                                self.peaks)
    local sampleCount = (value & 0xfffff)
    local extraType =   (value & 0x1000000) >> 24
    local outputMode =  (value & 0xf00000) >> 20

    self.numberOfPeaks = sampleCount
end]]--
function PitchEditor:updateEditorTakeWithSelectedItems()
    local item = reaper.GetSelectedMediaItem(0, 0)
    local take
    if item then take = reaper.GetActiveTake(item) end
    self.take:set(take)

    if self.take.pointer then
        self.track = self.take.track
        self.take:updatePitchPointTimes()
        self.take:updatePitchCorrectionTimes()
    else
        self.track = nil
    end
end
function PitchEditor:pixelsToTime(pixelsRelativeToEditor)
    if self.w <= 0 then return 0.0 end
    return self.take.length * (self.view.x.scroll + pixelsRelativeToEditor / (self.w * self.view.x.zoom))
end
function PitchEditor:timeToPixels(time)
    if self.take.length <= 0 then return 0 end
    return self.view.x.zoom * self.w * (time / self.take.length - self.view.x.scroll)
end
function PitchEditor:pixelsToPitch(pixelsRelativeToEditor)
    if self.h <= 0 then return 0.0 end
    return self.pitchHeight * (1.0 - (self.view.y.scroll + pixelsRelativeToEditor / (self.h * self.view.y.zoom))) - 0.5
end
function PitchEditor:pitchToPixels(pitch)
    if self.pitchHeight <= 0 then return 0 end
    return self.view.y.zoom * self.h * ((1.0 - (0.5 + pitch) / self.pitchHeight) - self.view.y.scroll)
end
function PitchEditor:calculateMouseInformation()
    self.previousMouseTime = self.mouseTime
    self.previousMousePitch = self.mousePitch
    self.previousSnappedMousePitch = self.snappedMousePitch

    self.mouseTime =  self:pixelsToTime(self.relativeMouseX)
    self.mousePitch = self:pixelsToPitch(self.relativeMouseY)
    self.mouseTimeChange = self.mouseTime - self.previousMouseTime
    self.mousePitchChange = self.mousePitch - self.previousMousePitch

    self.snappedMousePitch = round(self.mousePitch)
    self.snappedMousePitchChange = self.snappedMousePitch - self.previousSnappedMousePitch
end
function PitchEditor:setEditCursorToMousePosition()
    reaper.SetEditCurPos(self.take.leftTime + self.mouseTime, false, true)
    reaper.UpdateArrange()
end

--==============================================================
--== Events ====================================================
--==============================================================

function PitchEditor:handleWindowResize()
    if self.scaleWithWindow then
        self.w = self.w + self.GFX.wChange
        self.h = self.h + self.GFX.hChange
        self.view.x.scale = self.w
        self.view.y.scale = self.h
    end

    self:recalculatePitchCorrectionCoordinates()
    self:recalculateTakePitchCoordinates()
end
function PitchEditor:handleKeyPress(char)
    local keyPressFunction = self.keyPressFunctions[char]
    if keyPressFunction then keyPressFunction(self) end
end
function PitchEditor:handleLeftPress(mouse)
    self.mouseTimeOnLeftDown = self.mouseTime
    self.mousePitchOnLeftDown = self.mousePitch
    self.snappedMousePitchOnLeftDown = self.snappedMousePitch
    self:handlePitchCorrectionPointLeftDown(mouse)
end
function PitchEditor:handleLeftDrag(mouse)
    self:handlePitchCorrectionPointLeftDrag(mouse)
end
function PitchEditor:handleLeftRelease(mouse)
    if not mouse.buttons.left:justStoppedDragging() and not self.pitchCorrectionEditPoint then
        self:setEditCursorToMousePosition()
    end
    self:handlePitchCorrectionPointLeftUp(mouse)
end
function PitchEditor:handleLeftDoublePress(mouse)
    self:handlePitchCorrectionPointLeftDoubleClick(mouse)
end
function PitchEditor:handleMiddlePress(mouse)
    self.view.x.target = self.relativeMouseX
    self.view.y.target = self.relativeMouseY
end
function PitchEditor:handleMiddleDrag(mouse)
    if self.keyboard.modifiers.shift:isPressed() then
        self.view.x:changeZoom(mouse.xChange)
        self.view.y:changeZoom(mouse.yChange)
    else
        self.view.x:changeScroll(mouse.xChange)
        self.view.y:changeScroll(mouse.yChange)
    end

    self:recalculatePitchCorrectionCoordinates()
    self:recalculateTakePitchCoordinates()
end
function PitchEditor:handleRightPress(mouse)
    self.boxSelect:startSelection(self.relativeMouseX, self.relativeMouseY)
end
function PitchEditor:handleRightDrag(mouse)
    self.boxSelect:editSelection(self.relativeMouseX, self.relativeMouseY)
end
function PitchEditor:handleRightRelease(mouse)
    self.boxSelect:makeSelection(self.take.corrections.points, setPointSelected, pointIsSelected, self.keyboard.modifiers.shift:isPressed(), self.keyboard.modifiers.control:isPressed())
end
function PitchEditor:handleMouseWheel(mouse)
    local xSensitivity = 55.0
    local ySensitivity = 55.0

    self.view.x.target = self.relativeMouseX
    self.view.y.target = self.relativeMouseY

    if self.keyboard.modifiers.control:isPressed() then
        self.view.y:changeZoom(mouse.wheel * ySensitivity)
    else
        self.view.x:changeZoom(mouse.wheel * xSensitivity)
    end

    self:recalculatePitchCorrectionCoordinates()
    self:recalculateTakePitchCoordinates()
end

function PitchEditor:initialize()
    self:updateEditorTakeWithSelectedItems()
    self:handleWindowResize()
    self:calculateMouseInformation()

    --local time = self.take.sourceLength / 1000
    --local timeIncrement = time
    --for i = 1, 1000 do
    --    self:insertPitchCorrectionPoint{
    --        time = time,
    --        pitch = 20.0 * math.random() + 50,
    --        isActive = math.random() > 0.5,
    --        isSelected = false
    --    }
    --    time = time + timeIncrement
    --end
end
function PitchEditor:updateStates()
    local mouse = self.mouse
    local mouseLeftButton = mouse.buttons.left
    local mouseMiddleButton = mouse.buttons.middle
    local mouseRightButton = mouse.buttons.right
    local keyboard = self.keyboard
    local char = self.keyboard.currentCharacter

    if self:projectHasChanged() then
        if not self.take.isAnalyzingPitch then
            self:updateEditorTakeWithSelectedItems()
        end
        --self:updatePeaks()
    end
    if self.isVisible then
        self:calculateMouseInformation()
        self:updatePitchCorrectionMouseOver()
        self.take:analyzePitch()
        self:recalculatePitchCorrectionCoordinates()
        self:recalculateTakePitchCoordinates()
        self:queueRedraw()
    end
end
function PitchEditor:update()
    if self.GFX:windowWasResized() then self:handleWindowResize() end
    if char then self:handleKeyPress(char) end
    if mouseLeftButton:justPressed(self) then self:handleLeftPress(mouse) end
    if mouseLeftButton:justDragged(self) then self:handleLeftDrag(mouse) end
    if mouseLeftButton:justReleased(self) then self:handleLeftRelease(mouse) end
    if mouseLeftButton:justDoublePressed(self) then self:handleLeftDoublePress(mouse) end
    if mouseMiddleButton:justPressed(self) then self:handleMiddlePress(mouse) end
    if mouseMiddleButton:justDragged(self) then self:handleMiddleDrag(mouse) end
    if mouseRightButton:justPressed(self) then self:handleRightPress(mouse) end
    if mouseRightButton:justDragged(self) then self:handleRightDrag(mouse) end
    if mouseRightButton:justReleased(self) then self:handleRightRelease(mouse) end
    if mouse:wheelJustMoved(self) then self:handleMouseWheel(mouse) end
end
function PitchEditor:draw()
    self:drawMainBackground()
    self:drawKeyBackgrounds()
    --self:drawPeaks()
    self:drawTakePitchLines()
    self:drawEditCursor()
    self:drawPitchCorrections()
    self:drawEdges()
    self.boxSelect:draw()
end

PitchEditor.keyPressFunctions = {
    ["Delete"] = function(self)
        if not self.enablePitchCorrections then return end
        self:deleteSelectedPitchCorrectionPoints()
    end,
    ["e"] = function(self)
        self:setEditCursorToMousePosition()
        reaper.Main_OnCommandEx(1007, 0, 0)
    end,
    ["s"] = function(self)
        if not self.enablePitchCorrections then return end
        self:insertPitchCorrectionPoint{
            time = self.mouseTime,
            pitch = self.snappedMousePitch,
            isActive = false,
            isSelected = false
        }
        self.take:correctAllPitchPoints()
    end,
    ["S"] = function(self)
        if not self.enablePitchCorrections then return end
        self:insertPitchCorrectionPoint{
            time = self.mouseTime,
            pitch = self.mousePitch,
            isActive = false,
            isSelected = false
        }
        self.take:correctAllPitchPoints()
    end,
    ["Control+s"] = function(self)
        if not self.enablePitchCorrections then return end
        self.take:savePitchCorrections()
    end,
    ["d"] = function(self)
        if not self.enablePitchCorrections then return end
        self:insertPitchCorrectionPoint{
            time = self.mouseTime,
            pitch = self.snappedMousePitch,
            isActive = false,
            isSelected = false
        }
        local previousPoint = self.take.corrections.points[self.take.corrections.mostRecentInsertedIndex - 1]
        if previousPoint then previousPoint.isActive = true end
        self.take:correctAllPitchPoints()
    end,
    ["D"] = function(self)
        if not self.enablePitchCorrections then return end
        self:insertPitchCorrectionPoint{
            time = self.mouseTime,
            pitch = self.mousePitch,
            isActive = false,
            isSelected = false
        }
        local previousPoint = self.take.corrections.points[self.take.corrections.mostRecentInsertedIndex - 1]
        if previousPoint then previousPoint.isActive = true end
        self.take:correctAllPitchPoints()
    end,
}

return PitchEditor