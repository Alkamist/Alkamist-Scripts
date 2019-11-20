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
local whiteKeyNumbers = getWhiteKeyNumbers()
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
function KeyEditor:new(object)
    local self = Widget:new(self)

    self.backgroundColor = { 0.22, 0.22, 0.22, 1.0, 0 }
    self.blackKeyColor = { 0.22, 0.22, 0.22, 1.0, 0 }
    self.whiteKeyColor = { 0.29, 0.29, 0.29, 1.0, 0 }
    self.keyCenterLineColor = { 1.0, 1.0, 1.0, 0.09, 1 }
    self.edgeColor = { 1.0, 1.0, 1.0, -0.1, 1 }
    self.edgeShade = { 1.0, 1.0, 1.0, -0.04, 1 }
    self.editCursorColor = { 1.0, 1.0, 1.0, 0.34, 1 }
    self.playCursorColor = { 1.0, 1.0, 1.0, 0.2, 1 }
    self.minimumKeyHeightToDrawCenterLine = 16
    self.timeLength = 0
    self.startTime = 0
    self.pitchHeight = 128
    self.scaleWithWindow = true
    self.mouseTimeOnLeftDown = 0.0
    self.mousePitchOnLeftDown = 0.0
    self.snappedMousePitchOnLeftDown = 0.0
    self.mouseTime = { get = function(self) return self:pixelsToTime(self.relativeMouseX) end }
    self.previousMouseTime = 0
    self.mouseTimeChange = { get = function(self) return self.mouseTime - self.previousMouseTime end }
    self.mousePitch = { get = function(self) return self:pixelsToPitch(self.relativeMouseY) end }
    self.previousMousePitch = 0
    self.mousePitchChange = { get = function(self) return self.mousePitch - self.previousMousePitch end }
    self.snappedMousePitch = { get = function(self) return round(self.mousePitch) end }
    self.previousSnappedMousePitch = 0
    self.mouseSnappedPitchChange = { get = function(self) return self.snappedMousePitch - self.previousSnappedMousePitch end }
    self.xView = ViewAxis:new{ scale = object.width }
    self.yView = ViewAxis:new{ scale = object.height }

    --self.childWidgets = { _boxSelect }

    if object then for k, v in pairs(object) do self[k] = v end end
    return self
end

function KeyEditor:pixelsToTime(pixels)
    local width = self.width
    if width <= 0 then return 0.0 end
    local scroll = self.xView.scroll
    local zoom = self.xView.zoom
    local timeLength = self.timeLength
    return timeLength * (scroll + pixels / (width * zoom))
end
function KeyEditor:timeToPixels(time)
    local timeLength = self.timeLength
    if timeLength <= 0 then return 0 end
    local scroll = self.xView.scroll
    local zoom = self.xView.zoom
    local timeLength = self.timeLength
    local width = self.width
    return zoom * width * (time / timeLength - scroll)
end
function KeyEditor:pixelsToPitch(pixels)
    local height = self.height
    if height <= 0 then return 0.0 end
    local pitchHeight = self.pitchHeight
    local scroll = self.yView.scroll
    local zoom = self.yView.zoom
    return pitchHeight * (1.0 - (scroll + pixels / (height * zoom))) - 0.5
end
function KeyEditor:pitchToPixels(pitch)
    local pitchHeight = self.pitchHeight
    if pitchHeight <= 0 then return 0 end
    local height = self.height
    local scroll = self.yView.scroll
    local zoom = self.yView.zoom
    return zoom * height * ((1.0 - (0.5 + pitch) / pitchHeight) - scroll)
end

function KeyEditor:beginUpdate()
    self.previousMouseTime = self.mouseTime
    self.previousMousePitch = self.mousePitch
    self.previousSnappedMousePitch = self.snappedMousePitch
end
function KeyEditor:update()
    local GUI = self.GUI
    local controlKey = GUI.controlKey
    local shiftKey = GUI.shiftKey
    local leftMouseButton = GUI.leftMouseButton
    local middleMouseButton = GUI.middleMouseButton
    local rightMouseButton = GUI.rightMouseButton

    if GUI.windowWasResized then
        if self.scaleWithWindow then
            self.width = self.width + GUI.widthChange
            self.height = self.height + GUI.heightChange
            self.xView.scale = self.width
            self.yView.scale = self.height
        end
    end
    if leftMouseButton:justPressedWidget(self) then
        self.mouseTimeOnLeftDown = self.mouseTime
        self.mousePitchOnLeftDown = self.mousePitch
        self.snappedMousePitchOnLeftDown = self.snappedMousePitch
    end
    if middleMouseButton:justPressedWidget(self) then
        self.xView.target = self.relativeMouseX
        self.yView.target = self.relativeMouseY
    end
    if middleMouseButton:justDraggedWidget(self) then
        if shiftKey.isPressed then
            self.xView:changeZoom(GUI.mouseXChange)
            self.yView:changeZoom(GUI.mouseYChange)
        else
            self.xView:changeScroll(GUI.mouseXChange)
            self.yView:changeScroll(GUI.mouseYChange)
        end
    end
    if GUI.mouseWheelJustMoved and GUI:mouseIsInsideWidget(self) then
        local xSensitivity = 55.0
        local ySensitivity = 55.0

        self.xView.target = self.relativeMouseX
        self.yView.target = self.relativeMouseY

        if controlKey.isPressed then
            self.yView:changeZoom(GUI.mouseWheel * ySensitivity)
        else
            self.xView:changeZoom(GUI.mouseWheel * xSensitivity)
        end
    end

    self:queueRedraw()
end
function KeyEditor:drawKeyBackgrounds()
    local pitchHeight = self.pitchHeight
    local previousKeyEnd = self:pitchToPixels(pitchHeight + 0.5)
    local width = self.width
    local whiteKeyNumbers = whiteKeyNumbers
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
function KeyEditor:drawEdges()
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
function KeyEditor:drawEditCursor()
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
function KeyEditor:draw()
    local width = self.width
    local height = self.height
    self:setColor(self.backgroundColor)
    self:drawRectangle(0, 0, width, height, true)

    self:drawKeyBackgrounds()
    self:drawEdges()
    self:drawEditCursor()

    self:setColor(self.backgroundColor)
    self:drawRectangle(0, 0, width, _editorVerticalOffset, true)
end

return KeyEditor