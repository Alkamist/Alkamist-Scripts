local GUI = require("GUI")
local setColor = GUI.setColor
local drawLine = GUI.drawLine
local drawRectangle = GUI.drawRectangle

local ipairs = ipairs
local table = table
local tableInsert = table.insert

local whiteKeyMultiples = {1, 3, 4, 6, 8, 9, 11}
local whiteKeyNumbers = {}
for i = 1, 11 do
    for _, value in ipairs(whiteKeyMultiples) do
        tableInsert(whiteKeyNumbers, (i - 1) * 12 + value)
    end
end
local numberOfWhiteKeys = #whiteKeyNumbers

local function pixelsToTime(self, pixels) return self.timeLength * (self.xScroll + pixels / (self.width * self.xZoom)) end
local function timeToPixels(self, time) return self.xZoom * self.width * (time / self.timeLength - self.xScroll) end
local function pixelsToPitch(self, pixels) return self.pitchHeight * (1.0 - (self.yScroll + pixels / (self.height * self.yZoom))) - 0.5 end
local function pitchToPixels(self, pitch) return self.yZoom * self.height * ((1.0 - (0.5 + pitch) / self.pitchHeight) - self.yScroll) end

local function drawKeys(self)
    local x, y, w, h = self.x, self.y, self.width, self.height
    local pitchHeight = self.pitchHeight
    local previousKeyEnd = pitchToPixels(self, pitchHeight + 0.5)
    local blackKeyColor = self.blackKeyColor
    local whiteKeyColor = self.whiteKeyColor
    local keyCenterLineColor = self.keyCenterLineColor
    local minimumKeyHeightToDrawCenterLine = self.minimumKeyHeightToDrawCenterLine

    for i = 1, pitchHeight do
        local keyEnd = pitchToPixels(self, pitchHeight - i + 0.5)
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
            local keyCenterLine = pitchToPixels(self, pitchHeight - i)
            setColor(keyCenterLineColor)
            drawLine(x, y + keyCenterLine, x + w - 1, y + keyCenterLine, false)
        end

        previousKeyEnd = keyEnd
    end
end
local function drawEdges(self)
    local x, y, w, h = self.x, self.y, self.width, self.height

    setColor(self.edgeColor)
    local leftEdgePixels = timeToPixels(self, 0.0)
    local rightEdgePixels = timeToPixels(self, self.timeLength)
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
    local editCursorPixels = timeToPixels(self, reaper.GetCursorPosition() - timeStart)
    local playPositionPixels = timeToPixels(self, reaper.GetPlayPosition() - timeStart)

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

local KeyBackgroundDraw = {}

function KeyBackgroundDraw:requires()
    return self.KeyBackgroundDraw
end
function KeyBackgroundDraw:getDefaults()
    local defaults = {}
    defaults.x = 0
    defaults.y = 0
    defaults.width = 0
    defaults.height = 0
    defaults.timeLength = 0
    defaults.timeStart = 0
    defaults.xScroll = 0.0
    defaults.xZoom = 0.0
    defaults.yScroll = 0.0
    defaults.yZoom = 1.0
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
    return defaults
end
function KeyBackgroundDraw:update()
    drawKeys(self)
    drawEdges(self)
    drawEditCursor(self)
end

return KeyBackgroundDraw