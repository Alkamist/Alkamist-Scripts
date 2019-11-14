local reaper = reaper
local gfx = gfx
local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Widget = require("GUI.Widget")
local ViewAxis = require("GUI.ViewAxis")
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

return Prototype:new{
    initialize = function(self)
        self.view.x.scale = self.width
        self.view.y.scale = self.height
    end,

    prototypes = {
        { "widget", Widget:new() }
    },

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
    peakColor = { 1.0, 1.0, 1.0, 1.0, 0 },
    correctedPitchLineColor = { 0.3, 0.7, 0.3, 1.0, 0 },
    pitchLineColor = { 0.1, 0.3, 0.1, 1.0, 0 },

    minimumKeyHeightToDrawCenterLine = 16,
    pitchHeight = 128,
    editPixelRange = 7,
    scaleWithWindow = true,
    whiteKeyNumbers = getWhiteKeyNumbers(),
    mouseTimeOnLeftDown = 0.0,
    mousePitchOnLeftDown = 0.0,
    snappedMousePitchOnLeftDown = 0.0,
    altKeyWasDownOnPointEdit = false,
    fixErrorMode =  false,
    enablePitchCorrections = true,

    view = {
        x = ViewAxis:new(),
        y = ViewAxis:new()
    },

    mouseTime = { get = function(self, field) return self:pixelsToTime(self.relativeMouseX) end },
    previousMouseTime = { get = function(self, field) return self:pixelsToTime(self.previousRelativeMouseX) end },
    mouseTimeChange = { get = function(self, field) return self.mouseTime - self.previousMouseTime end },

    mousePitch = { get = function(self, field) return self:pixelsToPitch(self.relativeMouseY) end },
    previousMousePitch = { get = function(self, field) return self:pixelsToPitch(self.previousRelativeMouseY) end },
    mousePitchChange = { get = function(self, field) return self.mousePitch - self.previousMousePitch end },

    snappedMousePitch = { get = function(self, field) return round(self.mousePitch) end },
    snappedPreviousMousePitch = { get = function(self, field) return round(self.previousMousePitch) end },
    snappedMousePitchChange = { get = function(self, field) return self.snappedMousePitch - self.snappedPreviousMousePitch end },

    pixelsToTime = function(self, pixelsRelativeToEditor)
        local width = self.width
        if width <= 0 then return 0.0 end
        return self.take.length * (self.view.x.scroll + pixelsRelativeToEditor / (width * self.view.x.zoom))
    end,
    timeToPixels = function(self, time)
        local takeLength = self.take.length
        if takeLength <= 0 then return 0 end
        return self.view.x.zoom * self.width * (time / takeLength - self.view.x.scroll)
    end,
    pixelsToPitch = function(self, pixelsRelativeToEditor)
        local height = self.height
        if height <= 0 then return 0.0 end
        return self.pitchHeight * (1.0 - (self.view.y.scroll + pixelsRelativeToEditor / (height * self.view.y.zoom))) - 0.5
    end,
    pitchToPixels = function(self, pitch)
        local pitchHeight = self.pitchHeight
        if pitchHeight <= 0 then return 0 end
        return self.view.y.zoom * self.height * ((1.0 - (0.5 + pitch) / pitchHeight) - self.view.y.scroll)
    end,

    handleWindowResize = function(self)
        if self.scaleWithWindow then
            local GUI = self:getGUI()
            self.width = self.width + GUI:getWidthChange()
            self.height = self.height + GUI:getHeightChange()
            self.view.x.scale = self.width
            self.view.y.scale = self.height
        end
    end,
    handleLeftPress = function(self)
        self.mouseTimeOnLeftDown = self.mouseTime
        self.mousePitchOnLeftDown = self.mousePitch
        self.snappedMousePitchOnLeftDown = self.snappedMousePitch
    end,
    handleLeftDrag = function(self) end,
    handleLeftRelease = function(self) end,
    handleLeftDoublePress = function(self) end,
    handleMiddlePress = function(self)
        self.view.x.target = self.relativeMouseX
        self.view.y.target = self.relativeMouseY
    end,
    handleMiddleDrag = function(self)
        local mouse = self.mouse
        local shiftKey = self.keyboard.shiftKey
        if shiftKey.isPressed then
            self.view.x:changeZoom(mouse.xChange)
            self.view.y:changeZoom(mouse.yChange)
        else
            self.view.x:changeScroll(mouse.xChange)
            self.view.y:changeScroll(mouse.yChange)
        end
    end,
    handleRightPress = function(self) end,
    handleRightDrag = function(self) end,
    handleRightRelease = function(self) end,
    handleMouseWheel = function(self)
        local mouse = self.mouse
        local xSensitivity = 55.0
        local ySensitivity = 55.0
        local controlKey = self.keyboard.controlKey

        self.view.x.target = self.relativeMouseX
        self.view.y.target = self.relativeMouseY

        if controlKey.isPressed then
            self.view.y:changeZoom(mouse.wheel * ySensitivity)
        else
            self.view.y:changeZoom(mouse.wheel * xSensitivity)
        end
    end,

    drawKeyBackgrounds = function(self)
        local previousKeyEnd = self:pitchToPixels(self.pitchHeight + 0.5)
        local width = self.width

        for i = 1, self.pitchHeight do
            local keyEnd = self:pitchToPixels(self.pitchHeight - i + 0.5)
            local keyHeight = keyEnd - previousKeyEnd

            self:setColor(self.blackKeyColor)
            for _, value in ipairs(self.whiteKeyNumbers) do
                if i == value then
                    self:setColor(self.whiteKeyColor)
                end
            end
            self:drawRectangle(0, keyEnd, width, keyHeight + 1, true)

            self:setColor(self.blackKeyColor)
            self:drawLine(0, keyEnd, width - 1, keyEnd, false)

            if keyHeight > self.minimumKeyHeightToDrawCenterLine then
                local keyCenterLine = self:pitchToPixels(self.pitchHeight - i)

                self:setColor(self.keyCenterLineColor)
                self:drawLine(0, keyCenterLine, width - 1, keyCenterLine, false)
            end

            previousKeyEnd = keyEnd
        end
    end,
    update = function(self)
        local GUI = self:getGUI()
        local mouse = self.mouse
        local mouseLeftButton = mouse.leftButton
        local mouseMiddleButton = mouse.middleButton
        local mouseRightButton = mouse.rightButton

        --if GUI:windowWasResized() then self:handleWindowResize() end
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
        if mouse:wheelJustMovedWidget(self) then self:handleMouseWheel() end

        self.shouldRedraw = true
    end,
    draw = function(self)
        self:setColor(self.backgroundColor)
        self:drawRectangle(0, 0, self.width, self.height, true)

        self:drawKeyBackgrounds()
    end,
}