local GUI = require("GUI")
local setColor = GUI.setColor
local drawLine = GUI.drawLine
local drawRectangle = GUI.drawRectangle

local reaper = reaper
local ipairs = ipairs
local table = table
local tableInsert = table.insert
local math = math
local floor = math.floor
local ceil = math.ceil

local whiteKeyMultiples = {1, 3, 4, 6, 8, 9, 11}
local whiteKeyNumbers = {}
for i = 1, 11 do
    for _, value in ipairs(whiteKeyMultiples) do
        tableInsert(whiteKeyNumbers, (i - 1) * 12 + value)
    end
end
local numberOfWhiteKeys = #whiteKeyNumbers

local function round(number) return number > 0 and floor(number + 0.5) or ceil(number - 0.5) end
local function getNewScroll(change, zoom, scroll, scale) return scroll - change / (zoom * scale) end
local function getNewZoomAndScroll(change, zoom, scroll, target, scale)
    local target = target / scale
    local sensitivity = 0.01
    local change = 2 ^ (sensitivity * change)
    local zoom = zoom * change
    local scroll = scroll + (change - 1.0) * target / zoom
    return zoom, scroll
end
local function drawKeys(self)
    local x, y, w, h = self.x, self.y, self.width, self.height
    local pitchHeight = self.pitchHeight
    local previousKeyEnd = self:pitchToPixels(pitchHeight + 0.5)
    local blackKeyColor = self.blackKeyColor
    local whiteKeyColor = self.whiteKeyColor
    local keyCenterLineColor = self.keyCenterLineColor
    local minimumKeyHeightToDrawCenterLine = self.minimumKeyHeightToDrawCenterLine

    for i = 1, pitchHeight do
        local keyEnd = self:pitchToPixels(pitchHeight - i + 0.5)
        local keyHeight = keyEnd - previousKeyEnd

        setColor(blackKeyColor)
        for j = 1, numberOfWhiteKeys do
            local value = whiteKeyNumbers[j]
            if i == value then
                setColor(whiteKeyColor)
            end
        end
        drawRectangle(x, y + keyEnd, w, keyHeight + 1, true)

        setColor(blackKeyColor)
        drawLine(x, y + keyEnd, x + w - 1, y + keyEnd, false)

        if keyHeight > minimumKeyHeightToDrawCenterLine then
            local keyCenterLine = self:pitchToPixels(pitchHeight - i)
            setColor(keyCenterLineColor)
            drawLine(x, y + keyCenterLine, x + w - 1, y + keyCenterLine, false)
        end

        previousKeyEnd = keyEnd
    end
end
local function drawEdges(self)
    local x, y, w, h = self.x, self.y, self.width, self.height

    setColor(self.edgeColor)
    local leftEdgePixels = self:timeToPixels(0.0)
    local rightEdgePixels = self:timeToPixels(self.timeLength)
    drawLine(x + leftEdgePixels, y, x + leftEdgePixels, y + h, false)
    drawLine(x + rightEdgePixels, y, x + rightEdgePixels, y + h, false)

    setColor(self.edgeShade)
    drawRectangle(x, y, leftEdgePixels, h, true)
    local rightShadeStart = rightEdgePixels + 1
    drawRectangle(x + rightShadeStart, y, w - rightShadeStart, h, true)
end
local function drawEditCursor(self)
    local x, y, w, h = self.x, self.y, self.width, self.height
    local timeStart = self.timeStart
    local editCursorPixels = self:timeToPixels(reaper.GetCursorPosition() - timeStart)
    local playPositionPixels = self:timeToPixels(reaper.GetPlayPosition() - timeStart)

    setColor(self.editCursorColor)
    drawLine(x + editCursorPixels, y, x + editCursorPixels, y + h, false)

    local playState = reaper.GetPlayState()
    local projectIsPlaying = playState & 1 == 1
    local projectIsRecording = playState & 4 == 4
    if projectIsPlaying or projectIsRecording then
        setColor(self.playCursorColor)
        drawLine(x + playPositionPixels, y, x + playPositionPixels, y + h, false)
    end
end

local KeyEditor = {}

function KeyEditor:new()
    local self = self or {}

    local defaults = {}
    defaults.x = 0
    defaults.y = 0
    defaults.width = 0
    defaults.height = 0
    defaults.xZoom = 1.0
    defaults.xScroll = 0.0
    defaults.xTarget = 0.0
    defaults.yZoom = 1.0
    defaults.yScroll = 0.0
    defaults.yTarget = 0.0
    defaults.timeLength = 0.0
    defaults.timeStart = 0.0
    defaults.pitchHeight = 128
    defaults.minimumKeyHeightToDrawCenterLine = 16
    defaults.blackKeyColor = { 0.22, 0.22, 0.22, 1.0, 0 }
    defaults.whiteKeyColor = { 0.29, 0.29, 0.29, 1.0, 0 }
    defaults.keyCenterLineColor = { 1.0, 1.0, 1.0, 0.09, 1 }
    defaults.edgeColor = { 1.0, 1.0, 1.0, -0.1, 1 }
    defaults.edgeShade = { 1.0, 1.0, 1.0, -0.04, 1 }
    defaults.editCursorColor = { 1.0, 1.0, 1.0, 0.34, 1 }
    defaults.playCursorColor = { 1.0, 1.0, 1.0, 0.2, 1 }
    defaults.editCursorColor = { 1.0, 1.0, 1.0, 0.34, 1 }
    defaults.playCursorColor = { 1.0, 1.0, 1.0, 0.2, 1 }

    for k, v in pairs(defaults) do if self[k] == nil then self[k] = v end end
    for k, v in pairs(KeyEditor) do if self[k] == nil then self[k] = v end end
    return self
end
function KeyEditor:pixelsToTime(pixels) return self.timeLength * (self.xScroll + pixels / (self.width * self.xZoom)) end
function KeyEditor:timeToPixels(time) return self.xZoom * self.width * (time / self.timeLength - self.xScroll) end
function KeyEditor:pixelsToPitch(pixels) return self.pitchHeight * (1.0 - (self.yScroll + pixels / (self.height * self.yZoom))) - 0.5 end
function KeyEditor:pitchToPixels(pitch) return self.yZoom * self.height * ((1.0 - (0.5 + pitch) / self.pitchHeight) - self.yScroll) end
function KeyEditor:changeXScroll(change) self.xScroll = getNewScroll(change, self.xZoom, self.xScroll, self.width) end
function KeyEditor:changeYScroll(change) self.yScroll = getNewScroll(change, self.yZoom, self.yScroll, self.height) end
function KeyEditor:changeXZoom(change) self.xZoom, self.xScroll = getNewZoomAndScroll(change, self.xZoom, self.xScroll, self.xTarget, self.width) end
function KeyEditor:changeYZoom(change) self.yZoom, self.yScroll = getNewZoomAndScroll(change, self.yZoom, self.yScroll, self.yTarget, self.height) end
function KeyEditor:update(dt)
    self.relativeMouseX = GUI.mouseX - self.x
    self.relativeMouseY = GUI.mouseY - self.y

    self.mouseTime = self:pixelsToTime(self.relativeMouseX)
    self.snappedMouseTime = round(self.mouseTime)
    self.mousePitch = self:pixelsToPitch(self.relativeMouseY)
    self.snappedMousePitch = round(self.mousePitch)

    if GUI.windowWasJustResized then
        self.width = self.width + GUI.windowWidthChange
        self.height = self.height + GUI.windowHeightChange
    end
    if GUI.leftMouseButton.justPressed then
        self.mouseTimeOnLeftDown = self.mouseTime
        self.mousePitchOnLeftDown = self.mousePitch
        self.snappedMousePitchOnLeftDown = self.snappedMousePitch
    end
    if GUI.middleMouseButton.justPressed then
        self.xTarget = self.relativeMouseX
        self.yTarget = self.relativeMouseY
    end
    if GUI.middleMouseButton.justDragged then
        if GUI.shiftKey.isPressed then
            self:changeXZoom(GUI.mouseXChange)
            self:changeYZoom(GUI.mouseYChange)
        else
            self:changeXScroll(GUI.mouseXChange)
            self:changeYScroll(GUI.mouseYChange)
        end
    end
    if GUI.mouseWheelJustMoved then
        local xSensitivity = 55.0
        local ySensitivity = 55.0

        self.xTarget = self.relativeMouseX
        self.yTarget = self.relativeMouseY

        if GUI.controlKey.isPressed then
            self:changeYZoom(GUI.mouseWheel * ySensitivity)
        else
            self:changeXZoom(GUI.mouseWheel * xSensitivity)
        end
    end
end
function KeyEditor:draw(dt)
    drawKeys(self)
    --drawEdges(self)
    --drawEditCursor(self)
end

return KeyEditor