local reaper = reaper
local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Proxy = require("Proxy")
local Widget = require("GUI.Widget")
local ViewAxis = require("GUI.ViewAxis")
local Button = require("GUI.Button")
local Take = require("Pitch Correction.Take")
local PitchCorrectedTake = require("Pitch Correction.PitchCorrectedTake")
local BoxSelect = require("GUI.BoxSelect")

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
local function minimumDistanceBetweenPointAndLineSegment(pointX, pointY, lineX1, lineY1, lineX2, lineY2)
    if pointX == nil or pointY == nil or lineX1 == nil or lineY1 == nil or lineX2 == nil or lineY2 == nil then
        return 0.0
    end
    local A = pointX - lineX1
    local B = pointY - lineY1
    local C = lineX2 - lineX1
    local D = lineY2 - lineY1
    local dotProduct = A * C + B * D
    local lengthSquared = C * C + D * D
    local param = -1
    local xx
    local yy

    if lengthSquared ~= 0 then
        param = dotProduct / lengthSquared
    end

    if param < 0 then
        xx = lineX1
        yy = lineY1
    elseif param > 1 then
        xx = lineX2
        yy = lineY2
    else
        xx = lineX1 + param * C
        yy = lineY1 + param * D
    end

    local dx = pointX - xx
    local dy = pointY - yy

    return math.sqrt(dx * dx + dy * dy)
end
local function distanceBetweenTwoPoints(x1, y1, x2, y2)
    if x1 == nil or y1 == nil or x2 == nil or y2 == nil then
        return 0.0
    end
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end
local function getIndexAndDistanceOfSegmentClosestToPoint(points, x, y)
    local numberOfPoints = #points
    if numberOfPoints < 1 then return nil end

    local lowestDistance
    local lowestDistanceIndex = 1

    for i = 1, numberOfPoints do
        local point = points[i]
        local nextPoint = points[i + 1]

        local distance
        if nextPoint then
            distance = minimumDistanceBetweenPointAndLineSegment(x, y, point.x, point.y, nextPoint.x, nextPoint.y)
        end
        lowestDistance = lowestDistance or distance

        if distance and distance < lowestDistance then
            lowestDistance = distance
            lowestDistanceIndex = i
        end
    end

    return lowestDistanceIndex, lowestDistance
end
local function getIndexAndDistanceOfPointClosestToPoint(points, x, y)
    local numberOfPoints = #points
    if numberOfPoints < 1 then return nil end

    local lowestDistance
    local lowestDistanceIndex = 1

    for i = 1, numberOfPoints do
        local point = points[i]

        local distance = distanceBetweenTwoPoints(x, y, point.x, point.y)
        lowestDistance = lowestDistance or distance

        if distance and distance < lowestDistance then
            lowestDistance = distance
            lowestDistanceIndex = i
        end
    end

    return lowestDistanceIndex, lowestDistance
end
local function getIndexOfPointOrSegmentClosestToPointWithinDistance(points, x, y, distance)
    local index
    local indexIsPoint
    local segmentIndex, segmentDistance = getIndexAndDistanceOfSegmentClosestToPoint(points, x, y)
    local pointIndex, pointDistance = getIndexAndDistanceOfPointClosestToPoint(points, x, y)
    local pointIsClose = false
    local segmentIsClose = false

    if pointDistance then pointIsClose = pointDistance <= distance end
    if segmentDistance then segmentIsClose = segmentDistance <= distance end

    if pointIsClose or segmentIsClose then
        if segmentIsClose then
            index = segmentIndex
            indexIsPoint = false
        end
        if pointIsClose then
            index = pointIndex
            indexIsPoint = true
        end
    end
    return index, indexIsPoint
end

local PitchEditor = {}
function PitchEditor:new(parameters)
    local parameters = parameters or {}
    local self = Widget:new(parameters)

    self.width = 0
    self.height = 0
    self.editorVerticalOffset = 25
    self.editorHeight = { get = function(self) return self.height - self.editorVerticalOffset end }

    self.take = PitchCorrectedTake:new{ pointer = {
        get = function(self)
            local selectedItem = reaper.GetSelectedMediaItem(0, 0)
            if selectedItem then return reaper.GetActiveTake(selectedItem) end
        end
    } }
    self.timeLength = {
        get = function(self)
            local length = self.take.length
            if length then return length end
            return 0.0
        end
    }
    self.startTime = {
        get = function(self)
            local startTime = self.take.leftTime
            if startTime then return startTime end
            return 0.0
        end
    }

    self.fixErrorButton = Button:new{
        x = 79,
        y = 0,
        width = 80,
        height = 25,
        label = "Fix Errors",
        toggleOnClick = true
    }
    self.fixErrorMode = { get = function(self) return self.fixErrorButton.isPressed end }
    self.analyzeButton = Button:new{
        x = 0,
        y = 0,
        width = 80,
        height = 25,
        label = "Analyze Pitch",
        color = { 0.5, 0.2, 0.1, 1.0, 0 }
    }
    self.boxSelect = BoxSelect:new()
    self.widgets = { self.boxSelect, self.analyzeButton, self.fixErrorButton }

    self.backgroundColor = { 0.22, 0.22, 0.22, 1.0, 0 }
    self.blackKeyColor = { 0.22, 0.22, 0.22, 1.0, 0 }
    self.whiteKeyColor = { 0.29, 0.29, 0.29, 1.0, 0 }
    self.keyCenterLineColor = { 1.0, 1.0, 1.0, 0.09, 1 }
    self.edgeColor = { 1.0, 1.0, 1.0, -0.1, 1 }
    self.edgeShade = { 1.0, 1.0, 1.0, -0.04, 1 }
    self.editCursorColor = { 1.0, 1.0, 1.0, 0.34, 1 }
    self.playCursorColor = { 1.0, 1.0, 1.0, 0.2, 1 }
    self.pitchCorrectionActiveColor = { 0.3, 0.6, 0.9, 1.0, 0 }
    self.pitchCorrectionInactiveColor = { 0.9, 0.3, 0.3, 1.0, 0 }
    self.peakColor = { 1.0, 1.0, 1.0, 1.0, 0 }
    self.correctedPitchLineColor = { 0.24, 0.64, 0.24, 1.0, 0 }
    self.correctedPitchPointColor = { 0.3, 0.7, 0.3, 1.0, 0 }
    self.pitchLineColor = { 0.07, 0.27, 0.07, 1.0, 0 }
    self.pitchPointColor = { 0.1, 0.3, 0.1, 1.0, 0 }
    self.pitchPointMouseOverColor = { 0.6, 0.9, 0.6, 1.0, 0 }
    self.pitchLineMouseOverColor = { 0.53, 0.83, 0.53, 1.0, 0 }

    self.minimumKeyHeightToDrawCenterLine = 16
    self.pitchHeight = 128
    self.editPixelRange = 7
    self.scaleWithWindow = true
    self.whiteKeyNumbers = getWhiteKeyNumbers()
    self.mouseTimeOnLeftDown = 0.0
    self.mousePitchOnLeftDown = 0.0
    self.snappedMousePitchOnLeftDown = 0.0
    self.altKeyWasDownOnPointEdit = false
    self.enablePitchCorrections = true
    self.mouseIsOverPitchPoint = false
    self.mouseOverPitchPointIndex = nil

    self.mouseTime = { get = function(self) return self:pixelsToTime(self.relativeMouseX) end }
    self.previousMouseTime = { get = function(self) return self:pixelsToTime(self.previousRelativeMouseX) end }
    self.mouseTimeChange = { get = function(self) return self.mouseTime - self.previousMouseTime end }
    self.mousePitch = { get = function(self) return self:pixelsToPitch(self.relativeMouseY) end }
    self.previousMousePitch = { get = function(self) return self:pixelsToPitch(self.previousRelativeMouseY) end }
    self.mousePitchChange = { get = function(self) return self.mousePitch - self.previousMousePitch end }
    self.snappedMousePitch = { get = function(self) return round(self.mousePitch) end }
    self.snappedPreviousMousePitch = { get = function(self) return round(self.previousMousePitch) end }
    self.snappedMousePitchChange = { get = function(self) return self.snappedMousePitch - self.snappedPreviousMousePitch end }

    self.view = {
        x = ViewAxis:new(),
        y = ViewAxis:new()
    }

    function self:pixelsToTime(pixels)
        local width = self.width
        if width <= 0 then return 0.0 end
        return self.timeLength * (self.view.x.scroll + pixels / (width * self.view.x.zoom))
    end
    function self:timeToPixels(time)
        local takeLength = self.timeLength
        if takeLength <= 0 then return 0 end
        return self.view.x.zoom * self.width * (time / takeLength - self.view.x.scroll)
    end
    function self:pixelsToPitch(pixels)
        local pixels = pixels - self.editorVerticalOffset
        local height = self.editorHeight
        if height <= 0 then return 0.0 end
        return self.pitchHeight * (1.0 - (self.view.y.scroll + pixels / (height * self.view.y.zoom))) - 0.5
    end
    function self:pitchToPixels(pitch)
        local pitchHeight = self.pitchHeight
        if pitchHeight <= 0 then return 0 end
        return self.editorVerticalOffset + self.view.y.zoom * self.editorHeight * ((1.0 - (0.5 + pitch) / pitchHeight) - self.view.y.scroll)
    end
    function self:updatePointCoordinates(points)
        local timeToPixels = self.timeToPixels
        local pitchToPixels = self.pitchToPixels
        local reaperEnvelope_Evaluate = reaper.Envelope_Evaluate
        local envelope = self.take.pitchEnvelope
        local playRate = self.take.playRate
        for i = 1, #points do
            local point = points[i]
            point.time = self.take:getRealTime(point.sourceTime)
            local pointTime = point.time
            local pointPitch = point.pitch
            if pointTime then
                point.x = timeToPixels(self, pointTime)
                if pointPitch then
                    point.y = pitchToPixels(self, pointPitch)
                    local _, envelopeValue = reaperEnvelope_Evaluate(envelope, pointTime * playRate, 44100, 0)
                    point.correctedY = pitchToPixels(self, pointPitch + envelopeValue)
                end
            end
        end
    end
    function self:moveSelectedPitchPointsPitchesBy(value)
        local points = self.take.pitchAnalyzer.points
        for i = 1, #points do
            local point = points[i]
            if point.isSelected then
                point.pitch = point.pitch + value
            end
        end
    end

    self.keyPressFunctions = {
        ["Delete"] = function(self)
            msg("delete")
        end,
        ["e"] = function(self)
            reaper.SetEditCurPos(self.startTime + self.mouseTime, false, true)
            reaper.UpdateArrange()
            reaper.Main_OnCommandEx(1007, 0, 0)
        end,
        ["Down"] = function(self)
            if self.fixErrorMode then
                if self.GUI.keyboard.shiftKey.isPressed then
                    self:moveSelectedPitchPointsPitchesBy(-12.0)
                else
                    self:moveSelectedPitchPointsPitchesBy(-1.0)
                end
            end
        end,
        ["Up"] = function(self)
            if self.fixErrorMode then
                if self.GUI.keyboard.shiftKey.isPressed then
                    self:moveSelectedPitchPointsPitchesBy(12.0)
                else
                    self:moveSelectedPitchPointsPitchesBy(1.0)
                end
            end
        end
    }
    function self:handleWindowResize()
        if self.scaleWithWindow then
            local GUI = self.GUI
            self.width = self.width + GUI.widthChange
            self.height = self.height + GUI.heightChange
            self.view.x.scale = self.width
            self.view.y.scale = self.editorHeight
        end
    end
    function self:handleLeftPress()
        self.mouseTimeOnLeftDown = self.mouseTime
        self.mousePitchOnLeftDown = self.mousePitch
        self.snappedMousePitchOnLeftDown = self.snappedMousePitch
    end
    function self:handleLeftDrag() end
    function self:handleLeftRelease() end
    function self:handleLeftDoublePress() end
    function self:handleMiddlePress()
        self.view.x.target = self.relativeMouseX
        self.view.y.target = self.relativeMouseY - self.editorVerticalOffset
    end
    function self:handleMiddleDrag()
        local mouse = self.GUI.mouse
        local shiftKey = self.keyboard.shiftKey
        if shiftKey.isPressed then
            self.view.x:changeZoom(mouse.xChange)
            self.view.y:changeZoom(mouse.yChange)
        else
            self.view.x:changeScroll(mouse.xChange)
            self.view.y:changeScroll(mouse.yChange)
        end
    end
    function self:handleRightPress()
        self.boxSelect:startSelection(self.relativeMouseX, self.relativeMouseY)
    end
    function self:handleRightDrag()
        self.boxSelect:editSelection(self.relativeMouseX, self.relativeMouseY)
    end
    function self:handleRightRelease()
        local selectionParameters = {}
        if self.fixErrorMode then
            selectionParameters.thingsToSelect = self.take.pitchAnalyzer.points
            selectionParameters.isInsideFunction = function(box, thing)
                return box:pointIsInside(thing.x + self.absoluteX, thing.y + self.absoluteY)
            end
            selectionParameters.setSelectedFunction = function(point, shouldSelect)
                point.isSelected = shouldSelect
            end
            selectionParameters.getSelectedFunction = function(point)
                return point.isSelected
            end
            local keyboard = self.GUI.keyboard
            selectionParameters.shouldAdd = keyboard.shiftKey.isPressed
            selectionParameters.shouldInvert = keyboard.controlKey.isPressed
        end
        self.boxSelect:makeSelection(selectionParameters)
    end
    function self:handleMouseWheel()
        local mouse = self.GUI.mouse
        local xSensitivity = 55.0
        local ySensitivity = 55.0
        local controlKey = self.keyboard.controlKey

        self.view.x.target = self.relativeMouseX
        self.view.y.target = self.relativeMouseY - self.editorVerticalOffset

        if controlKey.isPressed then
            self.view.y:changeZoom(mouse.wheel * ySensitivity)
        else
            self.view.x:changeZoom(mouse.wheel * xSensitivity)
        end
    end

    local previousTakePointer = self.take.pointer
    function self:update()
        local GUI = self.GUI
        local mouse = self.GUI.mouse
        local mouseLeftButton = mouse.leftButton
        local mouseMiddleButton = mouse.middleButton
        local mouseRightButton = mouse.rightButton
        local pitchAnalyzer = self.take.pitchAnalyzer
        local takePointer = self.take.pointer

        if takePointer ~= previousTakePointer then
            pitchAnalyzer:loadPointsFromTakeFile()
        end

        if self.fixErrorMode then
            self.mouseOverPitchPointIndex, self.mouseIsOverPitchPoint = getIndexOfPointOrSegmentClosestToPointWithinDistance(pitchAnalyzer.points, self.relativeMouseX, self.relativeMouseY, self.editPixelRange)
        end

        if GUI.windowWasResized then self:handleWindowResize() end
        if mouseLeftButton:justPressedWidget(self) then self:handleLeftPress() end
        if mouseLeftButton:justDraggedWidget(self) then self:handleLeftDrag() end
        if mouseLeftButton:justReleasedWidget(self) then self:handleLeftRelease() end
        if mouseLeftButton:justDoublePressedWidget(self) then self:handleLeftDoublePress() end
        if mouseMiddleButton:justPressedWidget(self) then self:handleMiddlePress() end
        if mouseMiddleButton:justDraggedWidget(self) then self:handleMiddleDrag() end
        if mouseRightButton:justPressedWidget(self) then self:handleRightPress() end
        if mouseRightButton:justDraggedWidget(self) then self:handleRightDrag() end
        if mouseRightButton:justReleasedWidget(self) then self:handleRightRelease() end
        if mouse.wheelJustMoved and mouse:isInsideWidget(self) then self:handleMouseWheel() end

        if takePointer ~= nil then
            if self.analyzeButton.justPressed then pitchAnalyzer:prepareToAnalyzePitch() end
            pitchAnalyzer:analyzePitch()
            pitchAnalyzer:sortPoints()
            self:updatePointCoordinates(pitchAnalyzer.points)
        end

        self.shouldRedraw = true
        previousTakePointer = takePointer
    end
    function self:drawKeyBackgrounds()
        local pitchHeight = self.pitchHeight
        local previousKeyEnd = self:pitchToPixels(pitchHeight + 0.5)
        local width = self.width
        local whiteKeyNumbers = self.whiteKeyNumbers
        local numberOfWhiteKeys = #whiteKeyNumbers
        local blackKeyColor = self.blackKeyColor
        local whiteKeyColor = self.whiteKeyColor
        local keyCenterLineColor = self.keyCenterLineColor
        local minimumKeyHeightToDrawCenterLine = self.minimumKeyHeightToDrawCenterLine
        local pitchToPixels = self.pitchToPixels
        local setColor = self.setColor
        local drawLine = self.drawLine
        local drawRectangle = self.drawRectangle

        for i = 1, pitchHeight do
            local keyEnd = pitchToPixels(self, pitchHeight - i + 0.5)
            local keyHeight = keyEnd - previousKeyEnd

            setColor(self, blackKeyColor)
            for j = 1, numberOfWhiteKeys do
                local value = whiteKeyNumbers[j]
                if i == value then
                    setColor(self, whiteKeyColor)
                end
            end
            drawRectangle(self, 0, keyEnd, width, keyHeight + 1, true)

            setColor(self, blackKeyColor)
            drawLine(self, 0, keyEnd, width - 1, keyEnd, false)

            if keyHeight > minimumKeyHeightToDrawCenterLine then
                local keyCenterLine = pitchToPixels(self, pitchHeight - i)

                setColor(self, keyCenterLineColor)
                drawLine(self, 0, keyCenterLine, width - 1, keyCenterLine, false)
            end

            previousKeyEnd = keyEnd
        end
    end
    function self:drawEdges()
        if self.take.pointer == nil then return end
        local width = self.width
        local height = self.height

        self:setColor(self.edgeColor)
        local leftEdgePixels = self:timeToPixels(0.0)
        local rightEdgePixels = self:timeToPixels(self.timeLength)
        self:drawLine(leftEdgePixels, 0, leftEdgePixels, height, false)
        self:drawLine(rightEdgePixels, 0, rightEdgePixels, height, false)

        self:setColor(self.edgeShade)
        self:drawRectangle(0, 0, leftEdgePixels, height, true)
        local rightShadeStart = rightEdgePixels + 1
        self:drawRectangle(rightShadeStart, 0, width - rightShadeStart, height, true)
    end
    function self:drawEditCursor()
        local startTime = self.startTime
        local height = self.height
        local editCursorPixels = self:timeToPixels(reaper.GetCursorPosition() - startTime)
        local playPositionPixels = self:timeToPixels(reaper.GetPlayPosition() - startTime)

        self:setColor(self.editCursorColor)
        self:drawLine(editCursorPixels, 0, editCursorPixels, height, false)

        local playState = reaper.GetPlayState()
        local projectIsPlaying = playState & 1 == 1
        local projectIsRecording = playState & 4 == 4
        if projectIsPlaying or projectIsRecording then
            self:setColor(self.playCursorColor)
            self:drawLine(playPositionPixels, 0, playPositionPixels, height, false)
        end
    end
    function self:drawPitchPoints()
        if self.take.pointer == nil then return end
        local points = self.take.pitchAnalyzer.points
        local drawRectangle = self.drawRectangle
        local drawLine = self.drawLine
        local setColor = self.setColor
        local pointColor = self.pitchPointColor
        local lineColor = self.pitchLineColor
        local correctedLineColor = self.correctedPitchLineColor
        local mouseOverLineColor = self.pitchLineMouseOverColor
        local correctedPointColor = self.correctedPitchPointColor
        local mouseOverPointColor = self.pitchPointMouseOverColor
        local pitchToPixels = self.pitchToPixels
        local abs = math.abs
        local fixErrorMode = self.fixErrorMode
        local mouseOverIndex = self.mouseOverPitchPointIndex
        local mouseIsOverPoint = self.mouseIsOverPitchPoint
        local selectedColor = { 1.0, 1.0, 1.0, 0.3, 1 }
        for i = 1, #points do
            local point = points[i]
            local nextPoint = points[i + 1]
            local shouldDrawLine = nextPoint and abs(nextPoint.time - point.time) < 0.1

            if fixErrorMode then
                if shouldDrawLine then
                    if mouseOverIndex == i and not mouseIsOverPoint then
                        setColor(self, mouseOverLineColor)
                    else
                        setColor(self, correctedLineColor)
                    end
                    drawLine(self, point.x, point.y, nextPoint.x, nextPoint.y, true)
                end
                if mouseOverIndex == i and mouseIsOverPoint then
                    setColor(self, mouseOverPointColor)
                else
                    setColor(self, correctedPointColor)
                end
                drawRectangle(self, point.x - 1, point.y - 1, 3, 3, true)
                if point.isSelected then
                    setColor(self, selectedColor)
                    drawRectangle(self, point.x - 1, point.y - 1, 3, 3, true)
                end
            else
                if shouldDrawLine then
                    setColor(self, lineColor)
                    drawLine(self, point.x, point.y, nextPoint.x, nextPoint.y, true)
                end
                setColor(self, pointColor)
                drawRectangle(self, point.x - 1, point.y - 1, 3, 3, true)

                if shouldDrawLine then
                    setColor(self, correctedLineColor)
                    drawLine(self, point.x, point.correctedY, nextPoint.x, nextPoint.correctedY, true)
                end
                setColor(self, correctedPointColor)
                drawRectangle(self, point.x - 1, point.correctedY - 1, 3, 3, true)
            end
        end
    end
    function self:draw()
        self:setColor(self.backgroundColor)
        self:drawRectangle(0, 0, self.width, self.height, true)

        self:drawKeyBackgrounds()
        self:drawEdges()
        self:drawEditCursor()
        self:drawPitchPoints()

        self:setColor(self.backgroundColor)
        self:drawRectangle(0, 0, self.width, self.editorVerticalOffset, true)
    end

    for k, v in pairs(parameters) do self[k] = v end
    self.view.x.scale = self.width
    self.view.y.scale = self.editorHeight
    self.take.pitchAnalyzer:loadPointsFromTakeFile()
    return self
end

return PitchEditor