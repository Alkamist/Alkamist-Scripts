local reaper = reaper
local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Widget = require("GUI.Widget")
local ViewAxis = require("GUI.ViewAxis")

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
local function round(number, places)
    if not places then
        return number > 0 and math.floor(number + 0.5) or math.ceil(number - 0.5)
    else
        places = 10 ^ places
        return number > 0 and math.floor(number * places + 0.5)
                          or math.ceil(number * places - 0.5) / places
    end
end

local KeyEditor = {}
function KeyEditor:new(parameters)
    local parameters = parameters or {}
    local self = Widget:new(parameters)

    local _gui = self:getGUI()
    local _mouse = self:getMouse()
    local _keyboard = self:getKeyboard()
    local _whiteKeyNumbers = getWhiteKeyNumbers()
    local _backgroundColor = { 0.22, 0.22, 0.22, 1.0, 0 }
    local _blackKeyColor = { 0.22, 0.22, 0.22, 1.0, 0 }
    local _whiteKeyColor = { 0.29, 0.29, 0.29, 1.0, 0 }
    local _keyCenterLineColor = { 1.0, 1.0, 1.0, 0.09, 1 }
    local _minimumKeyHeightToDrawCenterLine = 16
    local _pitchHeight = 128
    local _scaleWithWindow = true
    local _mouseTimeOnLeftDown = 0.0
    local _mousePitchOnLeftDown = 0.0
    local _snappedMousePitchOnLeftDown = 0.0
    local _xView = ViewAxis:new()
    local _yView = ViewAxis:new()

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

    function self:update()
        local mouse = _mouse
        local controlKey = _keyboard:getControlKey()
        local shiftKey = _keyboard:getShiftKey()
        local mouseLeftButton = mouse:getLeftButton()
        local mouseMiddleButton = mouse:getMiddleButton()
        local mouseRightButton = mouse:getRightButton()

        if _gui:windowWasResized() then
            if _scaleWithWindow then
                self:setWidth(self:getWidth() + _gui:getWidthChange())
                self:setHeight(self:getHeight() + _gui:getHeightChange())
                _xView:setScale(self:getWidth())
                _yView:setScale(self:getHeight())
            end
        end
        if mouseLeftButton:justPressedWidget(self) then
            _mouseTimeOnLeftDown = self:getMouseTime()
            _mousePitchOnLeftDown = self:getMousePitch()
            _snappedMousePitchOnLeftDown = self:getSnappedMousePitch()
        end
        if mouseMiddleButton:justPressedWidget(self) then
            _xView:setTarget(self:getRelativeMouseX())
            _yView:setTarget(self:getRelativeMouseY())
        end
        if mouseMiddleButton:justDraggedWidget(self) then
            if shiftKey:isPressed() then
                _xView:changeZoom(mouse:getXChange())
                _yView:changeZoom(mouse:getYChange())
            else
                _xView:changeScroll(mouse:getXChange())
                _yView:changeScroll(mouse:getYChange())
            end
        end
        if _mouse:wheelJustMoved() and _mouse:isInsideWidget(self) then
            local xSensitivity = 55.0
            local ySensitivity = 55.0

            _xView:setTarget(self:getRelativeMouseX())
            _yView:setTarget(self:getRelativeMouseY())

            if controlKey:isPressed() then
                _xView:changeZoom(mouse:getWheelValue() * ySensitivity)
            else
                _yView:changeZoom(mouse:getWheelValue() * xSensitivity)
            end
        end

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

return KeyEditor