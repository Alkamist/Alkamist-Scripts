local reaper = reaper
local gfx = gfx
local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Widget = require("GUI.Widget")
local ViewAxis = require("GUI.ViewAxis")
local BoxSelect = require("GUI.BoxSelect")
--local PitchCorrectedTake = require("Pitch Correction.PitchCorrectedTake")

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

local function PitchEditor(parameters)
    local instance = Widget(parameters) or {}

    local _minimumKeyHeightToDrawCenterLine = parameters.minimumKeyHeightToDrawCenterLine or 16
    local _pitchHeight = parameters.pitchHeight or 128
    local _backgroundColor = parameters.backgroundColor or { 0.22, 0.22, 0.22, 1.0, 0 }
    local _blackKeyColor = parameters.blackKeyColor or { 0.22, 0.22, 0.22, 1.0, 0 }
    local _whiteKeyColor = parameters.whiteKeyColor or { 0.29, 0.29, 0.29, 1.0, 0 }
    local _keyCenterLineColor = parameters.keyCenterLineColor or { 1.0, 1.0, 1.0, 0.09, 1 }
    local _edgeColor = parameters.edgeColor or { 1.0, 1.0, 1.0, -0.1, 1 }
    local _edgeShade = parameters.edgeShade or { 1.0, 1.0, 1.0, -0.04, 1 }
    local _editCursorColor = parameters.editCursorColor or { 1.0, 1.0, 1.0, 0.34, 1 }
    local _playCursorColor = parameters.playCursorColor or { 1.0, 1.0, 1.0, 0.2, 1 }
    local _pitchCorrectionActiveColor = parameters.pitchCorrectionActiveColor or { 0.3, 0.6, 0.9, 1.0, 0 }
    local _pitchCorrectionInactiveColor = parameters.pitchCorrectionInactiveColor or { 0.9, 0.3, 0.3, 1.0, 0 }
    local _peakColor = parameters.peakColor or { 1.0, 1.0, 1.0, 1.0, 0 }
    local _correctedPitchLineColor = parameters.correctedPitchLineColor or { 0.3, 0.7, 0.3, 1.0, 0 }
    local _pitchLineColor = parameters.pitchLineColor or { 0.1, 0.3, 0.1, 1.0, 0 }
    local _editPixelRange = parameters.editPixelRange or 7
    local _scaleWithWindow = parameters.scaleWithWindow
    if _scaleWithWindow == nil then _scaleWithWindow = true end

    local _view = {
        x = ViewAxis(),
        y = ViewAxis()
    }
    --local _track = nil
    --local _take = PitchCorrectedTake:new()

    local _whiteKeyNumbers = getWhiteKeyNumbers()
    local _mouseTimeOnLeftDown = 0.0
    local _mousePitchOnLeftDown = 0.0
    local _snappedMousePitchOnLeftDown = 0.0
    local _altKeyWasDownOnPointEdit = false
    local _fixErrorMode =  false
    local _enablePitchCorrections = true

    --boxSelect = BoxSelect:new{
    --    parent = instance,
    --    thingsToSelect = _take.corrections
    --}
    --_elements = {
    --    [1] = _boxSelect
    --}

    function instance:pixelsToTime(pixelsRelativeToEditor)
        local width = instance:getWidth()
        if width <= 0 then return 0.0 end
        return _take:getLength() * (_view.x:getScroll() + pixelsRelativeToEditor / (width * _view.x:getZoom()))
    end
    function instance:timeToPixels(time)
        local takeLength = _take:getLength()
        if takeLength <= 0 then return 0 end
        return _view.x:getZoom() * instance:getWidth() * (time / takeLength - _view.x:getScroll())
    end
    function instance:pixelsToPitch(pixelsRelativeToEditor)
        if _h <= 0 then return 0.0 end
        return _pitchHeight * (1.0 - (_view.y:getScroll() + pixelsRelativeToEditor / (instance:getHeight() * _view.y:getZoom()))) - 0.5
    end
    function instance:pitchToPixels(pitch)
        if _pitchHeight <= 0 then return 0 end
        return _view.y:getZoom() * instance:getHeight() * ((1.0 - (0.5 + pitch) / _pitchHeight) - _view.y:getScroll())
    end

    function instance:getMouseTime() return instance:pixelsToTime(instance:getRelativeMouseX()) end
    function instance:getPreviousMouseTime() return instance:pixelsToTime(instance:getPreviousRelativeMouseX()) end
    function instance:getMouseTimeChange() return instance:getMouseTime() - instance:getPreviousMouseTime() end

    function instance:getMousePitch() return instance:pixelsToPitch(instance:getRelativeMouseY()) end
    function instance:getPreviousMousePitch() return instance:pixelsToPitch(instance:getPreviousRelativeMouseY()) end
    function instance:getMousePitchChange() return instance:getMousePitch() - instance:getPreviousMousePitch() end

    function instance:getSnappedMousePitch() return round(instance:getMousePitch()) end
    function instance:getPreviousSnappedMousePitch() return round(instance:getPreviousMousePitch()) end
    function instance:getSnappedMousePitchChange() return instance:getSnappedMousePitch() - instance:getPreviousSnappedMousePitch() end

    function instance:handleWindowResize()
        if _scaleWithWindow then
            local GUI = instance:getGUI()
            instance:setWidth(instance:getWidth() + GUI:getWidthChange())
            instance:setHeight(instance:getHeight() + GUI:getHeightChange())
            _view.x:setScale(instance:getWidth())
            _view.y:setScale(instance:getHeight())
        end
    end
    function instance:handleLeftPress()
        _mouseTimeOnLeftDown = instance:getMouseTime()
        _mousePitchOnLeftDown = instance:getMousePitch()
        _snappedMousePitchOnLeftDown = instance:getSnappedMousePitch()
    end
    function instance:handleLeftDrag() end
    function instance:handleLeftRelease() end
    function instance:handleLeftDoublePress() end
    function instance:handleMiddlePress()
        _view.x:setTarget(instance:getRelativeMouseX())
        _view.y:setTarget(instance:getRelativeMouseY())
    end
    function instance:handleMiddleDrag()
        local mouse = instance:getMouse()
        local shiftKey = instance:getKeyboard():getModifiers().shift
        if shiftKey:isPressed() then
            _view.x:changeZoom(mouse:getXChange())
            _view.y:changeZoom(mouse:getYChange())
        else
            _view.x:changeScroll(mouse:getXChange())
            _view.y:changeScroll(mouse:getYChange())
        end
    end
    function instance:handleRightPress() end
    function instance:handleRightDrag() end
    function instance:handleRightRelease() end
    function instance:handleMouseWheel()
        local mouse = instance:getMouse()
        local xSensitivity = 55.0
        local ySensitivity = 55.0
        local controlKey = instance:getKeyboard():getModifiers().control

        _view.x:setTarget(instance:getRelativeMouseX())
        _view.y:setTarget(instance:getRelativeMouseY())

        if controlKey:isPressed() then
            _view.y:changeZoom(mouse:getWheel() * ySensitivity)
        else
            _view.x:changeZoom(mouse:getHWheel() * xSensitivity)
        end
    end

    function instance:drawKeyBackgrounds()
        local previousKeyEnd = instance:pitchToPixels(_pitchHeight + 0.5)
        local width = instance:getWidth()

        for i = 1, _pitchHeight do
            local keyEnd = instance:pitchToPixels(_pitchHeight - i + 0.5)
            local keyHeight = keyEnd - previousKeyEnd

            instance:setColor(_blackKeyColor)
            for _, value in ipairs(_whiteKeyNumbers) do
                if i == value then
                    instance:setColor(_whiteKeyColor)
                end
            end
            instance:drawRectangle(0, keyEnd, width, keyHeight + 1, true)

            instance:setColor(_blackKeyColor)
            instance:drawLine(0, keyEnd, width - 1, keyEnd, false)

            if keyHeight > _minimumKeyHeightToDrawCenterLine then
                local keyCenterLine = instance:pitchToPixels(_pitchHeight - i)

                instance:setColor(_keyCenterLineColor)
                instance:drawLine(0, keyCenterLine, width - 1, keyCenterLine, false)
            end

            previousKeyEnd = keyEnd
        end
    end
    function instance:update()
        local GUI = instance:getGUI()
        local mouse = instance:getMouse()
        local mouseLeftButton = mouse:getButtons().left
        local mouseMiddleButton = mouse:getButtons().middle
        local mouseRightButton = mouse:getButtons().right

        if GUI:windowWasResized() then instance:handleWindowResize() end
        if char then instance:handleKeyPress(char) end
        if mouseLeftButton:justPressed(instance) then instance:handleLeftPress() end
        if mouseLeftButton:justDragged(instance) then instance:handleLeftDrag() end
        if mouseLeftButton:justReleased(instance) then instance:handleLeftRelease() end
        if mouseLeftButton:justDoublePressed(instance) then instance:handleLeftDoublePress() end
        if mouseMiddleButton:justPressed(instance) then instance:handleMiddlePress() end
        if mouseMiddleButton:justDragged(instance) then instance:handleMiddleDrag() end
        if mouseRightButton:justPressed(instance) then instance:handleRightPress() end
        if mouseRightButton:justDragged(instance) then instance:handleRightDrag() end
        if mouseRightButton:justReleased(instance) then instance:handleRightRelease() end
        if mouse:wheelJustMoved(instance) then instance:handleMouseWheel() end

        instance:queueRedraw()
    end
    function instance:draw()
        instance:setColor(_backgroundColor)
        instance:drawRectangle(0, 0, _w, _h, true)

        instance:drawKeyBackgrounds()
    end

    instance:handleWindowResize()
    return instance
end

return PitchEditor