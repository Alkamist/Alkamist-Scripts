local reaper = reaper
local gfx = gfx
local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ViewAxis =            require("GFX.ViewAxis")
local BoxSelect =           require("GFX.BoxSelect")
local PitchCorrectedTake =  require("Pitch Correction.PitchCorrectedTake")

--==============================================================
--== Local Functions ===========================================
--==============================================================

local function pointIsSelected(point)                return point.isSelected end
local function setPointSelected(point, shouldSelect) point.isSelected = shouldSelect end
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
local function drawPeaks(parent, color, x, y, w, h, take, startingTime, timeLength, numberOfChannels)
    local x =               round(x)
    local y =               round(y)
    local w =               round(w)
    local h =               round(h)
    local numberOfSamples = math.max(1, w)
    local peakrate =        round(w / timeLength)
    local item =            reaper.GetMediaItemTake_Item(take)
    local itemStart =       reaper.GetMediaItemInfo_Value(item, "D_POSITION")

    --local wantExtraType = 115  -- 's' char to get spectral information
    local wantExtraType = 0

    local reaperArray = reaper.new_array(numberOfSamples * numberOfChannels * 3)
    reaperArray.clear()
    local value = reaper.GetMediaItemTake_Peaks(take, peakrate, itemStart + startingTime, numberOfChannels, numberOfSamples, wantExtraType, reaperArray)
    local sampleCount = (value & 0xfffff)
    local extraType =   (value & 0x1000000) >> 24
    local outputMode =  (value & 0xf00000) >> 20

    local peaks = {}

    parent:setColor(color)
    if sampleCount > 0 then
        for i = 1, numberOfSamples do
            peaks[i] = reaperArray.table(i)
        end

        for i = 1, numberOfSamples do
            local peakMax = peaks[i][1]
            local peakMin = peaks[i][2]
            parent:drawLine(x + i, y - peakMax * h, x + i, y + peakMin * h, true)
            --local spectralPeak = reaperArray[numberOfSamples * 2 + i]
            --local peak = {
            --    max =          reaperArray[i],
            --    min =          reaperArray[numberOfSamples + i],
            --    lowFrequency = spectral & 0x7fff,
            --    tonality =     (spectral>>15) / 16384
            --}
            --self.peaks[i] = peak
        end
    end
end

--==============================================================
--== Initialization ============================================
--==============================================================

local PitchEditor = {}

function PitchEditor:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.x = init.x or 0
    self.y = init.y or 0
    self.w = init.w or 0
    self.h = init.h or 0

    self.whiteKeyNumbers =               getWhiteKeyNumbers()
    self.minKeyHeightToDrawCenterline =  init.minKeyHeightToDrawCenterline  or 16
    self.pitchHeight =                   init.pitchHeight                   or 128

    self.backgroundColor =               init.backgroundColor               or { 0.22, 0.22, 0.22, 1.0,  0 }
    self.blackKeyColor =                 init.blackKeyColor                 or { 0.22, 0.22, 0.22, 1.0,  0 }
    self.whiteKeyColor =                 init.whiteKeyColor                 or { 0.29, 0.29, 0.29, 1.0,  0 }
    self.keyCenterLineColor =            init.keyCenterLineColor            or { 1.0,  1.0,  1.0,  0.09, 1 }
    self.edgeColor =                     init.edgeColor                     or { 1.0,  1.0,  1.0,  -0.1, 1 }
    self.editCursorColor =               init.editCursorColor               or { 1.0,  1.0,  1.0,  0.34, 1 }
    self.playCursorColor =               init.playCursorColor               or { 1.0,  1.0,  1.0,  0.2,  1 }
    self.pitchCorrectionActiveColor =    init.pitchCorrectionActiveColor    or { 0.24, 0.54, 0.8,  1.0,  0 }
    self.pitchCorrectionInactiveColor =  init.pitchCorrectionInactiveColor  or { 0.8,  0.24, 0.24, 1.0,  0 }
    self.peakColor =                     init.peakColor                     or {1.0,   1.0,  1.0,  0.05, 1 }

    self.pitchCorrectionPixelRadius    = init.pitchCorrectionPixelRadius    or 3
    self.pitchCorrectionEditPixelRange = init.pitchCorrectionEditPixelRange or 7

    if init.scaleWithWindow ~= nil then self.scaleWithWindow = init.scaleWithWindow else self.scaleWithWindow = true end

    self.view = {
        x = ViewAxis:new{
            scale = self.w
        },
        y = ViewAxis:new{
            scale = self.h
        }
    }

    self.track = {}
    self.take =  PitchCorrectedTake:new()

    self.boxSelect = BoxSelect:new{
        parent = self,
        thingsToSelect = self.take.corrections
    }

    self.mouseTime =                 0.0
    self.mouseTimeOnLeftDown =       0.0
    self.previousMouseTime =         0.0
    self.mouseTimeChange =           0.0

    self.mousePitch =                0.0
    self.mousePitchOnLeftDown =      0.0
    self.previousMousePitch =        0.0
    self.mousePitchChange =          0.0
    self.snappedMousePitch =         0.0
    self.previousSnappedMousePitch = 0.0
    self.snappedMousePitchChange =   0.0

    self.altKeyWasDownOnPointEdit =      false
    self.mouseOverPitchCorrectionIndex = nil
    self.newPitchCorrectionPoint =       nil
    self.pitchCorrectionEditPoint =      nil

    return self
end

--==============================================================
--== Helpful Functions =========================================
--==============================================================

function PitchEditor:updateEditorTakeWithSelectedItems()
    local item = reaper.GetSelectedMediaItem(0, 0)
    local take
    if item then take = reaper.GetActiveTake(item) end
    self.take:set(take)

    if self.take.pointer then
        self.track = self.take.track
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

    self.mouseTime =  self:pixelsToTime(self.mouseX)
    self.mousePitch = self:pixelsToPitch(self.mouseY)
    self.mouseTimeChange = self.mouseTime - self.previousMouseTime
    self.mousePitchChange = self.mousePitch - self.previousMousePitch

    self.snappedMousePitch = round(self.mousePitch)
    self.snappedMousePitchChange = self.snappedMousePitch - self.previousSnappedMousePitch
end

--==============================================================
--== Pitch Correction Points ===================================
--==============================================================

function PitchEditor:insertPitchCorrectionPoint(point)
    self.take.corrections:insertPoint{
        x =          self:timeToPixels(point.time),
        y =          self:pitchToPixels(point.pitch),
        time =       point.time,
        pitch =      point.pitch,
        isSelected = point.isSelected,
        isActive =   point.isActive
    }
end
function PitchEditor:handlePitchCorrectionPointLeftDown()
    self.mouseTimeOnLeftDown =         self.mouseTime
    self.mousePitchOnLeftDown =        self.mousePitch
    self.snappedMousePitchOnLeftDown = self.snappedMousePitch

    self.altKeyWasDownOnPointEdit = false

    if self.mouseOverPitchCorrectionIndex then
        local point =     self.take.corrections.points[self.mouseOverPitchCorrectionIndex]
        local nextPoint = self.take.corrections.points[self.mouseOverPitchCorrectionIndex + 1]
        self.pitchCorrectionEditPoint = point

        local pointWasAlreadySelected = point.isSelected
        if not pointWasAlreadySelected then
            if not self.GFX.shiftKeyState then
                self:unselectAllPitchCorrectionPoints()
            end
            point.isSelected = true
        end

        if self.GFX.altKeyState then
            self.altKeyWasDownOnPointEdit = true
            self.take.corrections:applyFunctionToAllPoints(function(point)
                if point.isSelected then
                    point.isActive = not point.isActive
                end
            end)
        end

        if not self.mouseIsOverPoint then
            if nextPoint then nextPoint.isSelected = true end
        end
    end
end
function PitchEditor:handlePitchCorrectionPointLeftDrag()
    local mousePitch =           self.snappedMousePitch
    local mousePitchChange =     self.snappedMousePitchChange
    local mousePitchOnLeftDown = self.snappedMousePitchOnLeftDown

    if self.GFX.shiftKeyState then
        mousePitch =           self.mousePitch
        mousePitchChange =     self.mousePitchChange
        mousePitchOnLeftDown = self.mousePitchOnLeftDown
    end

    if not self.pitchCorrectionEditPoint and self.justStartedLeftDragging then
        self:unselectAllPitchCorrectionPoints()

        self:insertPitchCorrectionPoint{
            time = self.mouseTimeOnLeftDown,
            pitch = mousePitchOnLeftDown,
            isActive = true,
            isSelected = false
        }
        local firstPointIndex = self.take.corrections.mostRecentInsertedIndex

        local previousPoint = self.take.corrections.points[firstPointIndex - 1]
        if previousPoint and self.GFX.altKeyState then previousPoint.isActive = true end

        self:insertPitchCorrectionPoint{
            time = self.mouseTime,
            pitch = mousePitch,
            isActive = false,
            isSelected = true
        }
        local newPointIndex = self.take.corrections.mostRecentInsertedIndex
        self.newPitchCorrectionPoint = self.take.corrections.points[newPointIndex]
    elseif not self.altKeyWasDownOnPointEdit then
        self.take.corrections:applyFunctionToAllPoints(function(point)
            if point.isSelected then
                point.time =  point.time + self.mouseTimeChange
                point.pitch = point.pitch + mousePitchChange
                point.x =     self:timeToPixels(point.time)
                point.y =     self:pitchToPixels(point.pitch)
            end
        end)
        self.take.corrections:sortPoints()
    end
end
function PitchEditor:handlePitchCorrectionPointLeftUp()
    if self.newPitchCorrectionPoint then
        self.newPitchCorrectionPoint.isSelected = false
    end

    self.newPitchCorrectionPoint = nil
    self.pitchCorrectionEditPoint = nil
end
function PitchEditor:handlePitchCorrectionPointLeftDoubleClick()
    if self.mouseOverPitchCorrectionIndex and not self.newPitchCorrectionPoint then
        self:snapSelectedPitchCorrectionsToNearestPitch()
    end
end
function PitchEditor:recalculatePitchCorrectionCoordinates()
    self.take.corrections:applyFunctionToAllPoints(function(point)
        point.x = self:timeToPixels(point.time)
        point.y = self:pitchToPixels(point.pitch)
    end)
end
function PitchEditor:updatePitchCorrectionMouseOver()
    local segmentIndex, segmentDistance = self.take.corrections:getIndexAndDistanceOfSegmentClosestToPoint(self.mouseX, self.mouseY)
    local pointIndex,   pointDistance =   self.take.corrections:getIndexAndDistanceOfPointClosestToPoint(self.mouseX, self.mouseY)

    local pointIsClose = false
    local segmentIsClose = false

    if pointDistance then
        pointIsClose = pointDistance <= self.pitchCorrectionEditPixelRange
    end
    if segmentDistance then
        segmentIsClose = segmentDistance <= self.pitchCorrectionEditPixelRange and self.take.corrections.points[segmentIndex].isActive
    end

    if pointIsClose or segmentIsClose or self.pitchCorrectionEditPoint then
        if segmentIsClose or self.pitchCorrectionEditPoint then
            self.mouseOverPitchCorrectionIndex = segmentIndex
            self.mouseIsOverPoint = false
        end
        if pointIsClose then
            self.mouseOverPitchCorrectionIndex = pointIndex
            self.mouseIsOverPoint = true
        end
    else
        self.mouseOverPitchCorrectionIndex = nil
        self.mouseIsOverPoint = nil
    end
end
function PitchEditor:unselectAllPitchCorrectionPoints()
    self.take.corrections:applyFunctionToAllPoints(function(point)
        point.isSelected = false
    end)
end
function PitchEditor:snapSelectedPitchCorrectionsToNearestPitch()
    self.take.corrections:applyFunctionToAllPoints(function(point)
        if point.isSelected then
            point.pitch = round(point.pitch)
        end
    end)
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
function PitchEditor:drawPeaks()
    local x =                round( math.max(self:timeToPixels(0.0), 0) )
    local y =                round( self.h * 0.5 )
    local w =                round( math.min(self:timeToPixels(self.take.length) - x, self.w - x) )
    local h =                200
    local numberOfSamples =  math.max(1, w)
    local numberOfChannels = 1
    local startTime =        math.max(self:pixelsToTime(0), 0)
    local timeLength =       math.min(self:pixelsToTime(self.w), self.take.length) - startTime
    local peakrate =         w / timeLength

    --local wantExtraType = 115  -- 's' char to get spectral information
    local wantExtraType = 0

    local reaperArray = reaper.new_array(numberOfSamples * numberOfChannels * 3)
    reaperArray.clear()
    local value = reaper.GetMediaItemTake_Peaks(self.take.pointer,
                                                peakrate,
                                                self.take.leftTime + startTime,
                                                numberOfChannels,
                                                numberOfSamples,
                                                wantExtraType,
                                                reaperArray)
    local sampleCount = (value & 0xfffff)
    local extraType =   (value & 0x1000000) >> 24
    local outputMode =  (value & 0xf00000) >> 20

    local peaks = {}

    self:setColor(self.peakColor)
    if sampleCount > 0 then
        for i = 1, numberOfSamples do
            peaks[i] = reaperArray.table(i)
        end

        for i = 1, numberOfSamples do
            local peak = peaks[i]
            local nextPeak = peaks[i + 1]

            local peakMax = peak[1]
            local peakMin = peak[2]

            if nextPeak then
                local nextPeakMax = nextPeak[1]
                local nextPeakMin = nextPeak[2]

                self:drawLine(x + i, y - peakMax * h, x + i, y + nextPeakMax * h, true)
                --self:drawLine(x + i, y - peakMin * h, x + i + 1, y - nextPeakMin * h, true)
            end
            --local spectralPeak = reaperArray[numberOfSamples * 2 + i]
            --local peak = {
            --    max =          reaperArray[i],
            --    min =          reaperArray[numberOfSamples + i],
            --    lowFrequency = spectral & 0x7fff,
            --    tonality =     (spectral>>15) / 16384
            --}
            --self.peaks[i] = peak
        end
    end
end
function PitchEditor:drawEdges()
    self:setColor(self.edgeColor)
    local leftEdgePixels =  self:timeToPixels(0.0)
    local rightEdgePixels = self:timeToPixels(self.take.length)
    self:drawLine(leftEdgePixels, 0, leftEdgePixels, self.h, false)
    self:drawLine(rightEdgePixels, 0, rightEdgePixels, self.h, false)
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
function PitchEditor:drawPitchCorrectionSegment(index)
    local point =     self.take.corrections.points[index]
    local nextPoint = self.take.corrections.points[index + 1]
    local mouseIsOverSegment = index == self.mouseOverPitchCorrectionIndex and (not self.mouseIsOverPoint)

    self:setColor(self.pitchCorrectionActiveColor)

    if point.isActive and nextPoint then
        self:drawLine(point.x, point.y, nextPoint.x, nextPoint.y, true)
    end

    if mouseIsOverSegment and point.isActive and not self.newPitchCorrectionPoint and not self.pitchCorrectionEditPoint then
        self:setColor{1.0, 1.0, 1.0, 0.4, 1}
        self:drawLine(point.x, point.y, nextPoint.x, nextPoint.y, true)
    end
end
function PitchEditor:drawPitchCorrectionPoint(index)
    local point = self.take.corrections.points[index]
    local mouseIsOverThisPoint = index == self.mouseOverPitchCorrectionIndex and self.mouseIsOverPoint

    if point.isActive then
        self:setColor(self.pitchCorrectionActiveColor)
    else
        self:setColor(self.pitchCorrectionInactiveColor)
    end

    self:drawCircle(point.x, point.y, self.pitchCorrectionPixelRadius, true, true)

    if point.isSelected then
        self:setColor{1.0, 1.0, 1.0, 0.3, 1}
        self:drawCircle(point.x, point.y, self.pitchCorrectionPixelRadius, true, true)
    end

    if mouseIsOverThisPoint and not self.newPitchCorrectionPoint and not self.pitchCorrectionEditPoint then
        self:setColor{1.0, 1.0, 1.0, 0.3, 1}
        self:drawCircle(point.x, point.y, self.pitchCorrectionPixelRadius, true, true)
    end
end
function PitchEditor:drawPitchCorrections()
    -- Draw the active line segments.
    self:setColor(self.pitchCorrectionActiveColor)
    self.take.corrections:applyFunctionToAllPoints(function(point, index)
        self:drawPitchCorrectionSegment(index)
    end)

    -- Draw the points.
    self.take.corrections:applyFunctionToAllPoints(function(point, index)
        self:drawPitchCorrectionPoint(index)
    end)
end

--==============================================================
--== Events ====================================================
--==============================================================

function PitchEditor:onInit()
    self:updateEditorTakeWithSelectedItems()
    self:onWindowResize()
    self:calculateMouseInformation()

    local time = self.take.length / 100
    local timeIncrement = time
    for i = 1, 100 do
        self:insertPitchCorrectionPoint{
            time = time,
            pitch = 20.0 * math.random() + 50,
            isActive = math.random() > 0.5
        }
        time = time + timeIncrement
    end
end
function PitchEditor:onUpdate()
    if self.isVisible then
        self:calculateMouseInformation()
        self:updatePitchCorrectionMouseOver()
        self:queueRedraw()
        self:recalculatePitchCorrectionCoordinates()
    end

    self:updateEditorTakeWithSelectedItems()
end
function PitchEditor:onWindowResize()
    if self.scaleWithWindow then
        self.w = self.w + self.GFX.wChange
        self.h = self.h + self.GFX.hChange
        self.view.x.scale = self.w
        self.view.y.scale = self.h
    end

    self:recalculatePitchCorrectionCoordinates()
end
function PitchEditor:onKeyPress()
    local keyPressFunction = self.onKeyPressFunctions[self.GFX.char]
    if keyPressFunction then keyPressFunction(self) end
end
function PitchEditor:onMouseLeftDown()
    self:handlePitchCorrectionPointLeftDown()
end
function PitchEditor:onMouseLeftDrag()
    self:handlePitchCorrectionPointLeftDrag()
end
function PitchEditor:onMouseLeftUp()
    if not self.mouseLeftWasDragged and not self.pitchCorrectionEditPoint then
        reaper.SetEditCurPos(self.take.leftTime + self.mouseTime, false, true)
        reaper.UpdateArrange()
    end
    self:handlePitchCorrectionPointLeftUp()
end
function PitchEditor:onMouseLeftDoubleClick()
    self:handlePitchCorrectionPointLeftDoubleClick()
end
function PitchEditor:onMouseMiddleDown()
    self.view.x.target = self.mouseX
    self.view.y.target = self.mouseY
end
function PitchEditor:onMouseMiddleDrag()
    if self.GFX.shiftKeyState then
        self.view.x:changeZoom(self.GFX.mouseXChange)
        self.view.y:changeZoom(self.GFX.mouseYChange)
    else
        self.view.x:changeScroll(self.GFX.mouseXChange)
        self.view.y:changeScroll(self.GFX.mouseYChange)
    end

    self:recalculatePitchCorrectionCoordinates()
end
--function PitchEditor:onMouseMiddleUp() end
--function PitchEditor:onMouseMiddleDoubleClick() end
function PitchEditor:onMouseRightDown()
    self.boxSelect:startSelection(self.mouseX, self.mouseY)
end
function PitchEditor:onMouseRightDrag()
    self.boxSelect:editSelection(self.mouseX, self.mouseY)
end
function PitchEditor:onMouseRightUp()
    self.boxSelect:makeSelection(self.take.corrections.points, setPointSelected, pointIsSelected, self.GFX.shiftKeyState, self.GFX.controlKeyState)
end
--function PitchEditor:onMouseRightDoubleClick() end
function PitchEditor:onMouseWheel()
    local xSensitivity = 55.0
    local ySensitivity = 55.0

    self.view.x.target = self.mouseX
    self.view.y.target = self.mouseY

    if self.GFX.controlKeyState then
        self.view.y:changeZoom(self.GFX.wheel * ySensitivity)
    else
        self.view.x:changeZoom(self.GFX.wheel * xSensitivity)
    end

    self:recalculatePitchCorrectionCoordinates()
end
function PitchEditor:onDraw()
    self:drawMainBackground()
    self:drawKeyBackgrounds()
    self:drawPeaks()
    self:drawEdges()
    self:drawEditCursor()
    self:drawPitchCorrections()
    self.boxSelect:draw()
end

PitchEditor.onKeyPressFunctions = {
    ["Delete"] = function(self)
        arrayRemove(self.take.corrections.points, function(index)
            return self.take.corrections.points[index].isSelected
        end)
    end,
}

return PitchEditor