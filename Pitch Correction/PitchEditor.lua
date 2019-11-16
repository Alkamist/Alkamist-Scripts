local reaper = reaper
local gfx = gfx
local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Proxy = require("Proxy")
local Widget = require("GUI.Widget")
local ViewAxis = require("GUI.ViewAxis")
local PolyLine = require("GUI.PolyLine")
local Button = require("GUI.Button")
--local BoxSelect = require("GUI.BoxSelect")
--local PitchCorrectedTake = require("Pitch Correction.PitchCorrectedTake")

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

local PitchEditor = {}
function PitchEditor:new(initialValues)
    local self = Widget:new(initialValues)

    self.width = {
        value = self.width,
        get = function(self, field) return field.value end,
        set = function(self, value, field)
            field.value = value
            self.testLine.width = value
        end
    }
    self.height = {
        value = self.height,
        get = function(self, field) return field.value end,
        set = function(self, value, field)
            field.value = value
            self.testLine.height = value
        end
    }
    self.editorVerticalOffset = 26
    self.editorHeight = { get = function(self) return self.height - self.editorVerticalOffset end }

    self.testLine = PolyLine:new{ glowWhenMouseOver = true }
    self.analyzeButton = Button:new{
        x = 0,
        y = 0,
        width = 80,
        height = 25,
        label = "Analyze Pitch",
        color = { 0.5, 0.2, 0.1, 1.0, 0 }
    }
    self.fixErrorButton = Button:new{
        x = 81,
        y = 0,
        width = 80,
        height = 25,
        label = "Fix Errors",
        toggleOnClick = true
    }
    self.widgets = { self.testLine, self.analyzeButton, self.fixErrorButton }

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
    self.correctedPitchLineColor = { 0.3, 0.7, 0.3, 1.0, 0 }
    self.pitchLineColor = { 0.1, 0.3, 0.1, 1.0, 0 }

    self.minimumKeyHeightToDrawCenterLine = 16
    self.pitchHeight = 128
    self.editPixelRange = 7
    self.scaleWithWindow = true
    self.whiteKeyNumbers = getWhiteKeyNumbers()
    self.mouseTimeOnLeftDown = 0.0
    self.mousePitchOnLeftDown = 0.0
    self.snappedMousePitchOnLeftDown = 0.0
    self.altKeyWasDownOnPointEdit = false
    self.fixErrorMode = false
    self.enablePitchCorrections = true

    self.item = { get = function(self) return reaper.GetSelectedMediaItem(0, 0) end }
    self.take = {
        get = function(self)
            local item = self.item
            if item then return reaper.GetActiveTake(item) end
        end
    }
    self.timeLength = {
        get = function(self)
            local item = self.item
            if item then return reaper.GetMediaItemInfo_Value(item, "D_LENGTH") end
            return 0.0
        end
    }

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
        for i = 1, #points do
            local point = points[i]
            local pointTime = point.time
            local pointPitch = point.pitch
            if pointTime then point.x = timeToPixels(self, pointTime) end
            if pointPitch then point.y = pitchToPixels(self, pointPitch) end
        end
    end

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
    function self:handleRightPress() end
    function self:handleRightDrag() end
    function self:handleRightRelease() end
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
    function self:update()
        local GUI = self.GUI
        local mouse = self.GUI.mouse
        --local char = self.keyboard.currentCharacter
        local mouseLeftButton = mouse.leftButton
        local mouseMiddleButton = mouse.middleButton
        local mouseRightButton = mouse.rightButton

        if GUI.windowWasResized then self:handleWindowResize() end
        --if char then self:handleKeyPress(char) end
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

        self:updatePointCoordinates(self.testLine.points)
        self.shouldRedraw = true
    end
    function self:draw()
        self:setColor(self.backgroundColor)
        self:drawRectangle(0, 0, self.width, self.height, true)
        self:drawKeyBackgrounds()
        self:setColor(self.backgroundColor)
        self:drawRectangle(0, 0, self.width, self.editorVerticalOffset, true)
    end

    local proxy = Proxy:new(self, initialValues)
    proxy.view.x.scale = proxy.width
    proxy.view.y.scale = proxy.editorHeight

    local time = self.timeLength / 1000
    local timeIncrement = time
    for i = 1, 1000 do
        local pitch = 20.0 * math.random() + 50
        self.testLine:insertPoint{
            time = time,
            pitch = pitch,
            x = self:timeToPixels(time),
            y = self:pitchToPixels(pitch),
        }
        time = time + timeIncrement
    end

    return proxy
end

return PitchEditor