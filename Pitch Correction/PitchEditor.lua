local reaper = reaper
local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Widget = require("GUI.Widget")
local ViewAxis = require("GUI.ViewAxis")
local Button = require("GUI.Button")
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
local function drawPolyLine(parameters)
    local points = parameters.points
    local drawLineFunction = parameters.drawLineFunction
    local drawPointFunction = parameters.drawPointFunction
    local setColorFunction = parameters.setColorFunction
    local shouldDrawLineFunction = parameters.shouldDrawLineFunction
    local shouldDrawPointFunction = parameters.shouldDrawPointFunction
    local shouldGlowLineFunction = parameters.shouldGlowLineFunction
    local shouldGlowPointFunction = parameters.shouldGlowPointFunction
    local lineColor = parameters.lineColor
    local pointColor = parameters.pointColor
    local glowColor = { 1.0, 1.0, 1.0, 0.3, 1 }
    for i = 1, #points do
        local shouldDrawLine = shouldDrawLineFunction(i, points)
        local shouldDrawPoint = shouldDrawPointFunction(i, points)
        local shouldGlowLine = shouldGlowLineFunction(i, points)
        local shouldGlowPoint = shouldGlowPointFunction(i, points)
        if shouldDrawLine then
            setColorFunction(lineColor)
            drawLineFunction(i, points)
            if shouldGlowLine then
                setColorFunction(glowColor)
                drawLineFunction(i, points)
            end
        end
        if shouldDrawPoint then
            setColorFunction(pointColor)
            drawPointFunction(i, points)
            if shouldGlowPoint then
                setColorFunction(glowColor)
                drawPointFunction(i, points)
            end
        end
    end
end

local PitchEditor = {}
function PitchEditor:new(parameters)
    local parameters = parameters or {}
    local self = Widget:new(parameters)

    local _gui = self:getGUI()
    local _mouse = self:getMouse()
    local _keyboard = self:getKeyboard()
    local _backgroundColor = { 0.22, 0.22, 0.22, 1.0, 0 }
    local _blackKeyColor = { 0.22, 0.22, 0.22, 1.0, 0 }
    local _whiteKeyColor = { 0.29, 0.29, 0.29, 1.0, 0 }
    local _keyCenterLineColor = { 1.0, 1.0, 1.0, 0.09, 1 }
    local _edgeColor = { 1.0, 1.0, 1.0, -0.1, 1 }
    local _edgeShade = { 1.0, 1.0, 1.0, -0.04, 1 }
    local _editCursorColor = { 1.0, 1.0, 1.0, 0.34, 1 }
    local _playCursorColor = { 1.0, 1.0, 1.0, 0.2, 1 }
    local _pitchCorrectionActiveColor = { 0.3, 0.6, 0.9, 1.0, 0 }
    local _pitchCorrectionInactiveColor = { 0.9, 0.3, 0.3, 1.0, 0 }
    local _pitchLineColor = { 0.07, 0.27, 0.07, 1.0, 0 }
    local _correctedPitchLineColor = { 0.24, 0.64, 0.24, 1.0, 0 }
    local _minimumKeyHeightToDrawCenterLine = 16
    local _pitchHeight = 128
    local _editPixelRange = 7
    local _scaleWithWindow = true
    local _whiteKeyNumbers = getWhiteKeyNumbers()
    local _mouseTimeOnLeftDown = 0.0
    local _mousePitchOnLeftDown = 0.0
    local _snappedMousePitchOnLeftDown = 0.0
    local _altKeyWasDownOnPointEdit = false
    local _mouseIsOverPitchPoint = false
    local _mouseOverPitchPointIndex = nil
    local _editorVerticalOffset = 25
    local _view = {
        x = ViewAxis:new(),
        y = ViewAxis:new()
    }
    local _take = PitchCorrectedTake:new()
    local _fixEditorButton = Button:new{
        x = 79,
        y = 0,
        width = 80,
        height = 25,
        label = "Fix Errors",
        toggleOnClick = true
    }
    local _analyzeButton = Button:new{
        x = 0,
        y = 0,
        width = 80,
        height = 25,
        label = "Analyze Pitch",
        color = { 0.5, 0.2, 0.1, 1.0, 0 }
    }
    local _boxSelect = BoxSelect:new()

    local function _getEditorHeight() return self:getHeight() - _editorVerticalOffset end
    local function _getTimeLength()
        local length = _take:getLength()
        if length then return length end
        return 0.0
    end
    local function _getStartTime()
        local startTime = _take:getLeftTime()
        if startTime then return startTime end
        return 0.0
    end
    local function _getFixErrorMode() return _fixErrorButton:isPressed() end
    local function _pitchCorrectionsAreEnabled() return not _getFixErrorMode() end

    function self:pixelsToTime(pixels)
        local width = self:getWidth()
        if width <= 0 then return 0.0 end
        local scroll = _view.x:getScroll()
        local zoom = _view.x:getZoom()
        local timeLength = _getTimeLength()
        return timeLength * (scroll + pixels / (width * zoom))
    end
    function self:timeToPixels(time)
        local timeLength = self.timeLength
        if timeLength <= 0 then return 0 end
        local scroll = _view.x:getScroll()
        local zoom = _view.x:getZoom()
        local timeLength = _getTimeLength()
        local width = self:getWidth()
        return zoom * width * (time / timeLength - scroll)
    end
    function self:pixelsToPitch(pixels)
        local height = _getEditorHeight()
        if height <= 0 then return 0.0 end
        local pixels = pixels - _editorVerticalOffset
        local pitchHeight = _pitchHeight
        local scroll = _view.y:getScroll()
        local zoom = _view.y:getZoom()
        return pitchHeight * (1.0 - (scroll + pixels / (height * zoom))) - 0.5
    end
    function self:pitchToPixels(pitch)
        local pitchHeight = _pitchHeight
        if pitchHeight <= 0 then return 0 end
        local height = _getEditorHeight()
        local scroll = _view.y:getScroll()
        local zoom = _view.y:getZoom()
        return _editorVerticalOffset + zoom * height * ((1.0 - (0.5 + pitch) / pitchHeight) - scroll)
    end
    function self:getMouseTime() return self:pixelsToTime(self:getRelativeMouseX()) end
    function self:getPreviousMouseTime() return self:pixelsToTime(self:getPreviousRelativeMouseX()) end
    function self:getMouseTimeChange() return self:getMouseTime() - self:getPreviousMouseTime() end
    function self:getMousePitch() return self:pixelsToPitch(self:getRelativeMouseY()) end
    function self:getPreviousMousePitch() return self:pixelsToPitch(self:getPreviousRelativeMouseY()) end
    function self:getMousePitchChange() return self:getMousePitch() - self:getPreviousMousePitch() end
    function self:getSnappedMousePitch() return round(self:getMousePitch()) end
    function self:getPreviousSnappedMousePitch() return round(self:getPreviousMousePitch()) end
    function self:getMouseSnappedPitchChange() return self:getSnappedMousePitch() - self:getPreviousSnappedMousePitch() end

    --[[self.keyPressFunctions = {
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
        end,
        ["s"] = function(self)
            if not self.enablePitchCorrections then return end
            self:insertPitchCorrectionPoint{
                time = self.mouseTime,
                pitch = self.snappedMousePitch,
                isActive = false,
                isSelected = false
            }
            --self.take:correctAllPitchPoints()
        end,
        ["d"] = function(self)
            if not self.enablePitchCorrections then return end
            self:insertPitchCorrectionPoint{
                time = self.mouseTime,
                pitch = self.snappedMousePitch,
                isActive = true,
                isSelected = false
            }
            --self.take:correctAllPitchPoints()
        end
    }]]--
    function self:handleWindowResize()
        if _scaleWithWindow then
            self:setWidth(self:getWidth() + _gui:getWidthChange())
            self:setHeight(self:getHeight() + _gui:getHeightChange())
            _view.x:setScale(self:getWidth())
            _view.y:setScale(_getEditorHeight())
        end
    end
    function self:handleLeftPress()
        _mouseTimeOnLeftDown = self:getMouseTime()
        _mousePitchOnLeftDown = self:getMousePitch()
        _snappedMousePitchOnLeftDown = self:getSnappedMousePitch()
    end
    function self:handleLeftDrag() end
    function self:handleLeftRelease() end
    function self:handleLeftDoublePress() end
    function self:handleMiddlePress()
        _view.x:setTarget(self:getRelativeMouseX())
        _view.y:setTarget(self:getRelativeMouseY() - _editorVerticalOffset)
    end
    function self:handleMiddleDrag()
        local shiftKey = _keyboard:getShiftKey()
        if shiftKey:isPressed() then
            _view.x:changeZoom(_mouse:getXChange())
            _view.y:changeZoom(_mouse:getYChange())
        else
            _view.x:changeScroll(_mouse:getXChange())
            _view.y:changeScroll(_mouse:getYChange())
        end
    end
    function self:handleRightPress()
        _boxSelect:startSelection(self:getRelativeMouseX(), self:getRelativeMouseY())
    end
    function self:handleRightDrag()
        _boxSelect:editSelection(self:getRelativeMouseX(), self:getRelativeMouseY())
    end
    function self:handleRightRelease()
        --[[local selectionParameters = {}
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
        self.boxSelect:makeSelection(selectionParameters)]]--
        _boxSelect:makeSelection{}
    end
    function self:handleMouseWheel()
        local xSensitivity = 55.0
        local ySensitivity = 55.0
        local controlKey = _keyboard:getControlKey()

        _view.x:setTarget(self:getRelativeMouseX())
        _view.y:setTarget(self:getRelativeMouseY() - _editorVerticalOffset)

        if controlKey:isPressed() then
            _view.y:changeZoom(_mouse:getWheelValue() * ySensitivity)
        else
            _view.x:changeZoom(_mouse:getWheelValue() * xSensitivity)
        end
    end

    function self:update()
        local mouseLeftButton = _mouse:getLeftButton()
        local mouseMiddleButton = _mouse:getMiddleButton()
        local mouseRightButton = _mouse:getRightButton()

        if _gui:windowWasResized() then self:handleWindowResize() end
        if mouseLeftButton:justPressedWidget(self) then self:handleLeftPress() end
        if mouseLeftButton:justDraggedWidget(self) then self:handleLeftDrag() end
        if mouseLeftButton:justReleasedWidget(self) then self:handleLeftRelease() end
        if mouseLeftButton:justDoublePressedWidget(self) then self:handleLeftDoublePress() end
        if mouseMiddleButton:justPressedWidget(self) then self:handleMiddlePress() end
        if mouseMiddleButton:justDraggedWidget(self) then self:handleMiddleDrag() end
        if mouseRightButton:justPressedWidget(self) then self:handleRightPress() end
        if mouseRightButton:justDraggedWidget(self) then self:handleRightDrag() end
        if mouseRightButton:justReleasedWidget(self) then self:handleRightRelease() end
        if _mouse:wheelJustMoved() and _mouse:isInsideWidget(self) then self:handleMouseWheel() end

        self:queueRedraw()
    end
    function self:drawKeyBackgrounds()
        local pitchHeight = _pitchHeight
        local previousKeyEnd = self:pitchToPixels(pitchHeight + 0.5)
        local width = self:getWidth()
        local whiteKeyNumbers = _whiteKeyNumbers
        local numberOfWhiteKeys = #whiteKeyNumbers
        local blackKeyColor = _blackKeyColor
        local whiteKeyColor = _whiteKeyColor
        local keyCenterLineColor = _keyCenterLineColor
        local minimumKeyHeightToDrawCenterLine = _minimumKeyHeightToDrawCenterLine
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
        if _take:getPointer() == nil then return end
        local width = self:getWidth()
        local height = self:getHeight()

        self:setColor(_edgeColor)
        local leftEdgePixels = self:timeToPixels(0.0)
        local rightEdgePixels = self:timeToPixels(_getTimeLength())
        self:drawLine(leftEdgePixels, 0, leftEdgePixels, height, false)
        self:drawLine(rightEdgePixels, 0, rightEdgePixels, height, false)

        self:setColor(_edgeShade)
        self:drawRectangle(0, 0, leftEdgePixels, height, true)
        local rightShadeStart = rightEdgePixels + 1
        self:drawRectangle(rightShadeStart, 0, width - rightShadeStart, height, true)
    end
    function self:drawEditCursor()
        local startTime = _getStartTime()
        local height = self:getHeight()
        local editCursorPixels = self:timeToPixels(reaper.GetCursorPosition() - startTime)
        local playPositionPixels = self:timeToPixels(reaper.GetPlayPosition() - startTime)

        self:setColor(_editCursorColor)
        self:drawLine(editCursorPixels, 0, editCursorPixels, height, false)

        local playState = reaper.GetPlayState()
        local projectIsPlaying = playState & 1 == 1
        local projectIsRecording = playState & 4 == 4
        if projectIsPlaying or projectIsRecording then
            self:setColor(_playCursorColor)
            self:drawLine(playPositionPixels, 0, playPositionPixels, height, false)
        end
    end
    function self:draw()
        local width = self:getWidth()
        local height = self:getHeight()
        self:setColor(_backgroundColor)
        self:drawRectangle(0, 0, width, height, true)

        self:drawKeyBackgrounds()

        self:setColor(_backgroundColor)
        self:drawRectangle(0, 0, width, _editorVerticalOffset, true)
    end

    self:setChildWidgets{ _boxSelect, _analyzeButton, _fixErrorButton }
    return self
end

return PitchEditor