package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Alk = require "API.Alkamist API"

local function getWhiteKeys()
    local whiteKeyMultiples = {1, 3, 4, 6, 8, 9, 11}
    local whiteKeys = {}
    for i = 1, 11 do
        for _, value in ipairs(whiteKeyMultiples) do
            table.insert(whiteKeys, (i - 1) * 12 + value)
        end
    end
    return whiteKeys
end

local PitchEditor = {}
function PitchEditor:new(object)
    local object = object or {}
    object._base = self
    self.init(object)
    return object
end

function PitchEditor:init()
    setmetatable(self, self)
    self.xPixelOffset = self.xPixelOffset or 0
    self.yPixelOffset = self.yPixelOffset or 0
    self.pixelWidth = self.pixelWidth or 0
    self.pixelHeight = self.pixelHeight or 0
    self.whiteKeys = getWhiteKeys()
    self.pitchHeight = 128
    self:setItems()
    self:setUpFunctionalIndexes()

    self.minKeyHeightToDrawCenterline = self.minKeyHeightToDrawCenterline or 16
    self.blackKeyColor =      {0.2, 0.2, 0.2, 1.0}
    self.whiteKeyColor =      {0.5, 0.5, 0.5, 1.0}
    self.keyCenterLineColor = {1.0, 1.0, 1.0, 0.3}
    self.itemInsideColor =    {1.0, 1.0, 1.0, 0.1}
    self.itemEdgeColor =      {1.0, 1.0, 1.0, 0.2}
    self.editCursorColor =    {1.0, 1.0, 1.0, 0.4}
    self.playCursorColor =    {1.0, 1.0, 1.0, 0.3}

    self.view = {
        zoom = {
            x = 1.0,
            y = 1.0
        },
        scroll = {
            x = 0.0,
            y = 0.0
        }
    }
end

function PitchEditor:setItems()
    local topMostSelectedItemTrackNumber = #Alk.tracks
    for _, item in ipairs(Alk.selectedItems) do
        topMostSelectedItemTrackNumber = math.min(item.track.number, topMostSelectedItemTrackNumber)
    end
    self.track = Alk.tracks[topMostSelectedItemTrackNumber]
    self.items = self.track.selectedItems
end

function PitchEditor:setUpFunctionalIndexes()
    self.__index = function(tbl, key)
        if key == "timeWidth" then return self.items[#self.items].rightEdge - self.items[1].leftEdge end
        if key == "lefEdge" then return self.items[1].leftEdge end
        return self._base[key]
    end
end

function PitchEditor:pixelsToTime(xPixels)
    return self.timeWidth * (self.view.scroll.x + xPixels / (self.pixelWidth * self.view.zoom.x))
end
function PitchEditor:timeToPixels(time)
    return self.view.zoom.x * self.pixelWidth * (time / self.timeWidth - self.view.scroll.x)
end
function PitchEditor:pixelsToPitch(yPixels)
    return self.pitchHeight * (1.0 - (self.view.scroll.y + yPixels / (self.pixelHeight * self.view.zoom.y))) - 0.5
end
function PitchEditor:pitchToPixels(pitch)
    return self.view.zoom.y * self.pixelHeight * ((1.0 - (0.5 + pitch) / self.pitchHeight) - self.view.scroll.y)
end

function PitchEditor:rect(x, y, w, h, filled)
    gfx.rect(x + self.xPixelOffset, y + self.yPixelOffset, w, h, filled)
end
function PitchEditor:line(x, y, x2, y2, antiAliased)
    gfx.line(x + self.xPixelOffset,
             y + self.yPixelOffset,
             x2 + self.xPixelOffset,
             y2 + self.yPixelOffset,
             antiAliased)
end

function PitchEditor:draw()
    self:drawKeyBackgrounds()
    self:drawItemEdges()
    gfx.a = 1.0
end
function PitchEditor:drawKeyBackgrounds()
    local prevKeyEnd = self:pitchToPixels(self.pitchHeight + 0.5)
    for i = 1, self.pitchHeight do
        local keyEnd = self:pitchToPixels(self.pitchHeight - i + 0.5)
        local keyHeight = keyEnd - prevKeyEnd
        Alk.setColor(self.blackKeyColor)
        for _, value in ipairs(self.whiteKeys) do
            if i == value then
                Alk.setColor(self.whiteKeyColor)
            end
        end
        self:rect(0, keyEnd, self.pixelWidth, keyHeight + 1, 1)

        Alk.setColor(self.blackKeyColor)
        self:line(0, keyEnd, self.pixelWidth, keyEnd, false)

        if keyHeight > self.minKeyHeightToDrawCenterline then
            Alk.setColor(self.keyCenterLineColor)
            local keyCenterLine = self:pitchToPixels(self.pitchHeight - i)
            self:line(0, keyCenterLine, self.pixelWidth, keyCenterLine, false)
            prevKeyEnd = keyEnd
        end
    end
end
function PitchEditor:drawItemEdges()
    for index, item in ipairs(self.items) do
        local leftBoundTime = item.leftEdge - self.leftEdge
        local rightBoundTime = leftBoundTime + item.length
        local leftBoundPixels = self:getPixelsFromTime(leftBoundTime)
        local rightBoundPixels = self:getPixelsFromTime(rightBoundTime)
        local boxWidth = rightBoundPixels - leftBoundPixels
        local boxHeight = self.pixelHeight - 1
        Alk.setColor(self.itemInsideColor)
        self:rect(leftBoundPixels + 1, 2, boxWidth - 1, boxHeight - 1, 1)
        Alk.setColor(self.itemEdgeColor)
        self:rect(leftBoundPixels, 1, boxWidth, boxHeight, 0)
    end
end
function PitchEditor:drawEditCursor()
    local editCursorPosition = reaper.GetCursorPositionEx(0)
    local editCursorPixels = self:getPixelsFromTime(editCursorPosition - self.leftEdge)
    local playPosition = reaper.GetPlayPositionEx(0)
    local playPositionPixels = self:getPixelsFromTime(playPosition - self.leftEdge)
    Alk.setColor(self.editCursorColor)
    self:line(editCursorPixels, 0, editCursorPixels, self.pixelHeight, false)
    local projectPlaystate = reaper.GetPlayStateEx(0)
    local projectIsPlaying = projectPlaystate & 1 == 1 or projectPlaystate & 4 == 4
    if projectIsPlaying then
        Alk.setColor(self.playCursorColor)
        self:line(playPositionPixels, 0, playPositionPixels, self.pixelHeight, false)
    end
end