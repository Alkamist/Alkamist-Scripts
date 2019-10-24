local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ViewAxis =       require("GFX.ViewAxis")
local BoxSelect =      require("GFX.BoxSelect")
local PolyLine =       require("GFX.PolyLine")

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

--==============================================================
--== Initialization ============================================
--==============================================================

local PitchEditor = {}

function PitchEditor:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.x =     init.x or 0
    self.y =     init.y or 0
    self.w =     init.w or 0
    self.h =     init.h or 0

    self.whiteKeyNumbers =    getWhiteKeyNumbers()
    self.minKeyHeightToDrawCenterline = init.minKeyHeightToDrawCenterline   or 16
    self.pitchHeight =                  init.pitchHeight                    or 128

    self.backgroundColor =               init.backgroundColor               or { 0.2,  0.2,  0.2,  1.0,  0 }
    self.blackKeyColor =                 init.blackKeyColor                 or { 0.2,  0.2,  0.2,  1.0,  0 }
    self.whiteKeyColor =                 init.whiteKeyColor                 or { 0.28, 0.28, 0.28, 1.0,  0 }
    self.keyCenterLineColor =            init.keyCenterLineColor            or { 1.0,  1.0,  1.0,  0.12, 1 }
    self.itemInsideColor =               init.itemInsideColor               or { 1.0,  1.0,  1.0,  0.02, 1 }
    self.itemEdgeColor =                 init.itemEdgeColor                 or { 1.0,  1.0,  1.0,  0.15, 1 }
    self.editCursorColor =               init.editCursorColor               or { 1.0,  1.0,  1.0,  0.34, 1 }
    self.playCursorColor =               init.playCursorColor               or { 1.0,  1.0,  1.0,  0.2,  1 }
    self.pitchCorrectionActiveColor =    init.pitchCorrectionActiveColor    or { 0.24,  0.54,  0.8,  1.0,  0 }
    self.pitchCorrectionInactiveColor =  init.pitchCorrectionInactiveColor  or { 0.8,  0.24,  0.24,  1.0,  0 }

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
    self.items = {}

    self.pitchCorrections = PolyLine:new()
    self.boxSelect = BoxSelect:new{
        parent = self,
        thingsToSelect = self.pitchCorrections.points
    }

    self.mouseTime =            0.0
    self.previousMouseTime =    0.0
    self.mouseTimeChange =      0.0
    self.mousePitch =           0.0
    self.mouseTimeOnLeftDown =  0.0
    self.mousePitchOnLeftDown = 0.0
    self.previousMousePitch =   0.0
    self.mousePitchChange =     0.0
    self.leftEdge =             0.0
    self.rightEdge =            0.0
    self.timeWidth =            0.0

    return self
end

--==============================================================
--== Helpful Functions =========================================
--==============================================================

function PitchEditor:updateSelectedItems()
    local numberOfSelectedItems = reaper.CountSelectedMediaItems(0)
    local topMostSelectedItemTrackNumber = reaper.CountTracks(0)

    self.items = {}

    for i = 1, numberOfSelectedItems do
        local item =        reaper.GetSelectedMediaItem(0, i - 1)
        local track =       reaper.GetMediaItemTrack(item)
        local trackNumber = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        topMostSelectedItemTrackNumber = math.min(topMostSelectedItemTrackNumber, trackNumber)
    end
    self.track = reaper.GetTrack(0, topMostSelectedItemTrackNumber - 1)

    for i = 1, numberOfSelectedItems do
        local item = reaper.GetSelectedMediaItem(0, i - 1)
        if self.track == reaper.GetMediaItemTrack(item) then
            self.items[#self.items + 1] = item
        end
    end

    local numberOfItems = #self.items
    if numberOfItems > 0 then
        local leftMostItem = self.items[1]
        local rightMostItem = self.items[numberOfItems]
        self.leftEdge =  reaper.GetMediaItemInfo_Value(leftMostItem, "D_POSITION")
        self.rightEdge = reaper.GetMediaItemInfo_Value(rightMostItem, "D_POSITION") + reaper.GetMediaItemInfo_Value(rightMostItem, "D_LENGTH")
        self.timeWidth = self.rightEdge - self.leftEdge;
    else
        self.leftEdge = 0
        self.rightEdge = 0
        self.timeWidth = 0
    end
end
function PitchEditor:pixelsToTime(relativePixels)
    if self.w <= 0 then return 0.0 end
    return self.timeWidth * (self.view.x.scroll + relativePixels / (self.w * self.view.x.zoom))
end
function PitchEditor:timeToPixels(time)
    if self.timeWidth <= 0 then return 0 end
    return self.view.x.zoom * self.w * (time / self.timeWidth - self.view.x.scroll)
end
function PitchEditor:pixelsToPitch(relativePixels)
    if self.h <= 0 then return 0.0 end
    return self.pitchHeight * (1.0 - (self.view.y.scroll + relativePixels / (self.h * self.view.y.zoom))) - 0.5
end
function PitchEditor:pitchToPixels(pitch)
    if self.pitchHeight <= 0 then return 0 end
    return self.view.y.zoom * self.h * ((1.0 - (0.5 + pitch) / self.pitchHeight) - self.view.y.scroll)
end
function PitchEditor:calculateMouseInformation()
    self.previousMouseTime = self.mouseTime
    self.previousMousePitch = self.mousePitch
    self.mouseTime =  self:pixelsToTime(self.mouseX)
    self.mousePitch = self:pixelsToPitch(self.mouseY)
    self.mouseTimeChange = self.mouseTime - self.previousMouseTime
    self.mousePitchChange = self.mousePitch - self.previousMousePitch
end

--==============================================================
--== Pitch Correction Nodes ====================================
--==============================================================

function PitchEditor:insertPitchCorrectionPoint(point)
    return self.pitchCorrections:insertPoint{
        x =          self:timeToPixels(point.time),
        y =          self:pitchToPixels(point.pitch),
        time =       point.time,
        pitch =      point.pitch,
        isSelected = point.isSelected,
        isActive =   point.isActive
    }
end
function PitchEditor:recalculatePitchCorrectionCoordinates()
    self.pitchCorrections:applyFunctionToAllPoints(function(point)
        point.x = self:timeToPixels(point.time)
        point.y = self:pitchToPixels(point.pitch)
    end)
end
function PitchEditor:updatePitchCorrectionMouseOver()
    local segmentIndex, segmentDistance = self.pitchCorrections:getIndexAndDistanceOfSegmentClosestToPoint(self.mouseX, self.mouseY)
    local pointIndex,   pointDistance =   self.pitchCorrections:getIndexAndDistanceOfPointClosestToPoint(self.mouseX, self.mouseY)

    local pointIsClose = false
    local segmentIsClose = false

    if pointDistance then
        pointIsClose = pointDistance <= self.pitchCorrectionEditPixelRange
    end
    if segmentDistance then
        segmentIsClose = segmentDistance <= self.pitchCorrectionEditPixelRange and self.pitchCorrections.points[segmentIndex].isActive
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
    self.pitchCorrections:applyFunctionToAllPoints(function(point)
        point.isSelected = false
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
function PitchEditor:drawItemEdges()
    local numberOfItems = #self.items
    for i = 1, numberOfItems do
        local item = self.items[i]
        local leftBoundTime = reaper.GetMediaItemInfo_Value(item, "D_POSITION") - self.leftEdge
        local rightBoundTime = leftBoundTime + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local leftBoundPixels = self:timeToPixels(leftBoundTime)
        local rightBoundPixels = self:timeToPixels(rightBoundTime)
        local boxWidth = rightBoundPixels - leftBoundPixels
        local boxHeight = self.h - 2

        self:setColor(self.itemInsideColor)
        self:drawRectangle(leftBoundPixels + 1, 2, boxWidth - 2, boxHeight - 2, true)

        self:setColor(self.itemEdgeColor)
        self:drawRectangle(leftBoundPixels, 1, boxWidth, boxHeight, false)
    end
end
function PitchEditor:drawEditCursor()
    local editCursorPixels =   self:timeToPixels(reaper.GetCursorPosition() - self.leftEdge)
    local playPositionPixels = self:timeToPixels(reaper.GetPlayPosition() - self.leftEdge)

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
    local point =     self.pitchCorrections.points[index]
    local nextPoint = self.pitchCorrections.points[index + 1]
    local mouseIsOverSegment = index == self.mouseOverPitchCorrectionIndex and (not self.mouseIsOverPoint)

    self:setColor(self.pitchCorrectionActiveColor)

    if point.isActive and nextPoint then
        self:drawLine(point.x, point.y, nextPoint.x, nextPoint.y, true)
    end

    if mouseIsOverSegment and point.isActive and not self.newPitchCorrectionPoint then
        self:setColor{1.0, 1.0, 1.0, 0.4, 1}
        self:drawLine(point.x, point.y, nextPoint.x, nextPoint.y, true)
    end
end
function PitchEditor:drawPitchCorrectionPoint(index)
    local point = self.pitchCorrections.points[index]
    local mouseIsOverThisPoint = index == self.mouseOverPitchCorrectionIndex and self.mouseIsOverPoint

    if point.isActive then
        self:setColor(self.pitchCorrectionActiveColor)
    else
        self:setColor(self.pitchCorrectionInactiveColor)
    end

    self:drawCircle(point.x, point.y, self.pitchCorrectionPixelRadius, true, true)

    if point.isSelected then
        self:setColor{1.0, 1.0, 1.0, 0.4, 1}
        self:drawCircle(point.x, point.y, self.pitchCorrectionPixelRadius, true, true)
    end

    if mouseIsOverThisPoint and not self.newPitchCorrectionPoint then
        self:setColor{1.0, 1.0, 1.0, 0.4, 1}
        self:drawCircle(point.x, point.y, self.pitchCorrectionPixelRadius, true, true)
    end
end
function PitchEditor:drawPitchCorrections()
    -- Draw the active line segments.
    self:setColor(self.pitchCorrectionActiveColor)
    self.pitchCorrections:applyFunctionToAllPoints(function(point, index)
        self:drawPitchCorrectionSegment(index)
    end)

    -- Draw the points.
    self.pitchCorrections:applyFunctionToAllPoints(function(point, index)
        self:drawPitchCorrectionPoint(index)
    end)
end

--==============================================================
--== Events ====================================================
--==============================================================

function PitchEditor:onInit()
    self:updateSelectedItems()
    self:onWindowResize()
    self:calculateMouseInformation()

    --local time = self.timeWidth / 2000
    --local timeIncrement = time
    --for i = 1, 2000 do
    --    self:insertPitchCorrectionPoint{
    --        time = time,
    --        pitch = 20.0 * math.random() + 50,
    --        isActive = math.random() > 0.5
    --    }
    --    time = time + timeIncrement
    --end
end
function PitchEditor:onUpdate()
    if self.isVisible then
        self:calculateMouseInformation()
        self:updatePitchCorrectionMouseOver()
        self:queueRedraw()
    end

    self:updateSelectedItems()
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
    self.mouseTimeOnLeftDown = self.mouseTime
    self.mousePitchOnLeftDown = self.mousePitch

    if self.mouseOverPitchCorrectionIndex then
        local point =     self.pitchCorrections.points[self.mouseOverPitchCorrectionIndex]
        local nextPoint = self.pitchCorrections.points[self.mouseOverPitchCorrectionIndex + 1]
        self.pitchCorrectionEditPoint = point

        if not self.GFX.shiftKeyState then
            self:unselectAllPitchCorrectionPoints()
        end

        point.isSelected = true
        if self.GFX.altKeyState then
            self.pitchCorrections:applyFunctionToAllPoints(function(point)
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
function PitchEditor:onMouseLeftDrag()
    if not self.pitchCorrectionEditPoint and self.justStartedLeftDragging then
        self:unselectAllPitchCorrectionPoints()

        local firstPointIndex = self:insertPitchCorrectionPoint{
            time = self.mouseTimeOnLeftDown,
            pitch = self.mousePitchOnLeftDown,
            isActive = true,
            isSelected = false
        }

        local previousPoint = self.pitchCorrections.points[firstPointIndex - 1]
        if previousPoint and self.GFX.altKeyState then previousPoint.isActive = true end

        local newPointIndex = self:insertPitchCorrectionPoint{
            time = self.mouseTime,
            pitch = self.mousePitch,
            isActive = false,
            isSelected = true
        }
        self.newPitchCorrectionPoint = self.pitchCorrections.points[newPointIndex]
    else
        self.pitchCorrections:applyFunctionToAllPoints(function(point)
            if point.isSelected then
                point.x =     point.x + self.GFX.mouseXChange
                point.y =     point.y + self.GFX.mouseYChange
                point.time =  point.time + self.mouseTimeChange
                point.pitch = point.pitch + self.mousePitchChange
            end
        end)
        self.pitchCorrections:sortPoints()
    end
end
function PitchEditor:onMouseLeftUp()
    self.newPitchCorrectionPoint = nil
    self.pitchCorrectionEditPoint = nil

    if not self.mouseLeftWasDragged then
        reaper.SetEditCurPos(self.leftEdge + self.mouseTime, false, true)
        reaper.UpdateArrange()
    end
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
--function PitchEditor:onMouseMiddleUp()
--end
function PitchEditor:onMouseRightDown()
    self.boxSelect:startSelection(self.mouseX, self.mouseY)
end
function PitchEditor:onMouseRightDrag()
    self.boxSelect:editSelection(self.mouseX, self.mouseY)
end
function PitchEditor:onMouseRightUp()
    self.boxSelect:makeSelection(self.pitchCorrections.points, setPointSelected, pointIsSelected, self.GFX.shiftKeyState, self.GFX.controlKeyState)
end
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
    self:drawItemEdges()
    self:drawEditCursor()
    self:drawPitchCorrections()
    self.boxSelect:draw()
end

PitchEditor.onKeyPressFunctions = {
    ["Delete"] = function(self)
        arrayRemove(self.pitchCorrections.points, function(index)
            return self.pitchCorrections.points[index].isSelected
        end)
    end,
}

return PitchEditor