package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Alk = require "API.Alkamist API"
local GFX = require "GFX.Alkamist GFX"

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
    self.__index = self._base
    setmetatable(self, self)
    self.x = self.x or 0
    self.y = self.y or 0
    self.w = self.w or 0
    self.h = self.h or 0
    self.whiteKeys = getWhiteKeys()
    self.pitchHeight = 128
    self:updateSelectedItems()
    self:setUpFunctionalIndexes()

    self.minKeyHeightToDrawCenterline = self.minKeyHeightToDrawCenterline or 16
    self.blackKeyColor = self.blackKeyColor           or {0.25, 0.25, 0.25, 1.0}
    self.whiteKeyColor = self.whiteKeyColor           or {0.34, 0.34, 0.34, 1.0}
    self.keyCenterLineColor = self.keyCenterLineColor or {1.0, 1.0, 1.0, 0.12}
    self.itemInsideColor = self.itemInsideColor       or {1.0, 1.0, 1.0, 0.02}
    self.itemEdgeColor = self.itemEdgeColor           or {1.0, 1.0, 1.0, 0.1}
    self.editCursorColor = self.editCursorColor       or {1.0, 1.0, 1.0, 0.4}
    self.playCursorColor = self.playCursorColor       or {1.0, 1.0, 1.0, 0.3}

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

function PitchEditor:updateSelectedItems()
    local topMostSelectedItemTrackNumber = #Alk.tracks
    for _, item in ipairs(Alk.selectedItems) do
        topMostSelectedItemTrackNumber = math.min(item.track.number, topMostSelectedItemTrackNumber)
    end
    self.track = Alk.tracks[topMostSelectedItemTrackNumber]
    self.items = self.track.selectedItems
end
function PitchEditor:setUpFunctionalIndexes()
    self.__index = function(tbl, key)
        if key == "timeWidth" then
            if self.items[1] and self.items[#self.items] then
                return self.items[#self.items].rightEdge - self.items[1].leftEdge
            end
            return 0
        end
        if key == "leftEdge" then
            if self.items[1] then
                return self.items[1].leftEdge
            end
            return 0
        end
        return self._base[key]
    end
end

function PitchEditor:pixelsToTime(xPixels)
    return self.timeWidth * (self.view.scroll.x + xPixels / (self.w * self.view.zoom.x))
end
function PitchEditor:timeToPixels(time)
    return self.view.zoom.x * self.w * (time / self.timeWidth - self.view.scroll.x)
end
function PitchEditor:pixelsToPitch(yPixels)
    return self.pitchHeight * (1.0 - (self.view.scroll.y + yPixels / (self.h * self.view.zoom.y))) - 0.5
end
function PitchEditor:pitchToPixels(pitch)
    return self.view.zoom.y * self.h * ((1.0 - (0.5 + pitch) / self.pitchHeight) - self.view.scroll.y)
end

---------------------- Drawing Code ----------------------

function PitchEditor:rect(x, y, w, h, filled)
    gfx.rect(x + self.x, y + self.y, w, h, filled)
end
function PitchEditor:line(x, y, x2, y2, antiAliased)
    gfx.line(x + self.x,
             y + self.y,
             x2 + self.x,
             y2 + self.y,
             antiAliased)
end

function PitchEditor:drawKeyBackgrounds()
    local prevKeyEnd = self:pitchToPixels(self.pitchHeight + 0.5)
    for i = 1, self.pitchHeight do
        local keyEnd = self:pitchToPixels(self.pitchHeight - i + 0.5)
        local keyHeight = keyEnd - prevKeyEnd
        GFX.setColor(self.blackKeyColor)
        for _, value in ipairs(self.whiteKeys) do
            if i == value then
                GFX.setColor(self.whiteKeyColor)
            end
        end
        self:rect(0, keyEnd, self.w, keyHeight + 1, 1)

        GFX.setColor(self.blackKeyColor)
        self:line(0, keyEnd, self.w, keyEnd, false)

        if keyHeight > self.minKeyHeightToDrawCenterline then
            GFX.setColor(self.keyCenterLineColor)
            local keyCenterLine = self:pitchToPixels(self.pitchHeight - i)
            self:line(0, keyCenterLine, self.w, keyCenterLine, false)
        end

        prevKeyEnd = keyEnd
    end
end
function PitchEditor:drawItemEdges()
    for index, item in ipairs(self.items) do
        local leftBoundTime = item.leftEdge - self.leftEdge
        local rightBoundTime = leftBoundTime + item.length
        local leftBoundPixels = self:timeToPixels(leftBoundTime)
        local rightBoundPixels = self:timeToPixels(rightBoundTime)
        local boxWidth = rightBoundPixels - leftBoundPixels
        local boxHeight = self.h - 2
        GFX.setColor(self.itemInsideColor)
        self:rect(leftBoundPixels + 1, 2, boxWidth - 2, boxHeight - 2, 1)
        GFX.setColor(self.itemEdgeColor)
        self:rect(leftBoundPixels, 1, boxWidth, boxHeight, 0)
    end
end
function PitchEditor:drawEditCursor()
    local editCursorPosition = reaper.GetCursorPositionEx(0)
    local editCursorPixels = self:timeToPixels(editCursorPosition - self.leftEdge)
    local playPosition = reaper.GetPlayPositionEx(0)
    local playPositionPixels = self:timeToPixels(playPosition - self.leftEdge)
    GFX.setColor(self.editCursorColor)
    self:line(editCursorPixels, 0, editCursorPixels, self.h, false)
    local projectPlaystate = reaper.GetPlayStateEx(0)
    local projectIsPlaying = projectPlaystate & 1 == 1 or projectPlaystate & 4 == 4
    if projectIsPlaying then
        GFX.setColor(self.playCursorColor)
        self:line(playPositionPixels, 0, playPositionPixels, self.h, false)
    end
end

---------------------- Events ----------------------
function PitchEditor:pointIsInside(point)
    return point.x >= self.x and point.x <= self.x + self.w
       and point.y >= self.y and point.y <= self.y + self.h
end
function PitchEditor:mouseIsInside()
    return self:pointIsInside({ x = GFX.mouseX, y = GFX.mouseY })
end
function PitchEditor:mouseJustEntered()
    return self:pointIsInside({ x = GFX.mouseX, y = GFX.mouseY })
    and (not self:pointIsInside({ x = GFX.prevMouseX, y = GFX.prevMouseY }) )
end
function PitchEditor:mouseJustLeft()
    return ( not self:pointIsInside({ x = GFX.mouseX, y = GFX.mouseY }) )
       and self:pointIsInside({ x = GFX.prevMouseX, y = GFX.prevMouseY })
end
function PitchEditor:onUpdate()
end
function PitchEditor:onResize()
    self.w = gfx.w
    self.h = gfx.h
end
function PitchEditor:onMouseEnter()
    msg("onMouseEnter")
end
function PitchEditor:onMouseLeave()
    msg("onMouseLeave")
end
function PitchEditor:onLeftMouseDown()
    msg("onLeftMouseDown")
end
function PitchEditor:onLeftMouseUp()
    msg("onLeftMouseUp")
end
function PitchEditor:onLeftMouseDrag()
    msg("onLeftMouseDrag")
end
function PitchEditor:onMiddleMouseDown()
    msg("onMiddleMouseDown")
end
function PitchEditor:onMiddleMouseUp()
    msg("onMiddleMouseUp")
end
function PitchEditor:onMiddleMouseDrag()
    msg("onMiddleMouseDrag")
end
function PitchEditor:onRightMouseDown()
    msg("onRightMouseDown")
end
function PitchEditor:onRightMouseUp()
    msg("onRightMouseUp")
end
function PitchEditor:onRightMouseDrag()
    msg("onRightMouseDrag")
end
function PitchEditor:onMouseWheel(numTicks)
    msg("onMouseWheel " .. tostring(numTicks))
end
function PitchEditor:onMouseHWheel(numTicks)
    msg("onMouseHWheel " .. tostring(numTicks))
end
function PitchEditor:draw()
    self:drawKeyBackgrounds()
    self:drawItemEdges()
    self:drawEditCursor()
    --gfx.a = 1.0
end

return PitchEditor