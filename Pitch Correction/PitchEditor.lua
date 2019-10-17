package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Alk = require "API.Alkamist API"
local GFX = require "GFX.Alkamist GFX"
local GFXChild = require "GFX.GFXChild"
local View = require "GFX.View"

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

local PitchEditor = setmetatable({}, { __index = GFXChild })
function PitchEditor:new(object)
    local object = object or {}
    object._base = self
    self.init(object)
    return object
end

function PitchEditor:init()
    GFXChild.init(self)
    self.__index = self._base
    setmetatable(self, self)
    self.w = GFX.w
    self.h = GFX.h - self.y
    self.whiteKeyNumbers = getWhiteKeyNumbers()
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

    self.view = View:new{
        xScale = self.w,
        yScale = self.h
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

function PitchEditor:drawKeyBackgrounds()
    local prevKeyEnd = self:pitchToPixels(self.pitchHeight + 0.5)
    for i = 1, self.pitchHeight do
        local keyEnd = self:pitchToPixels(self.pitchHeight - i + 0.5)
        local keyHeight = keyEnd - prevKeyEnd
        GFX.setColor(self.blackKeyColor)
        for _, value in ipairs(self.whiteKeyNumbers) do
            if i == value then
                GFX.setColor(self.whiteKeyColor)
            end
        end
        self:rect(0, keyEnd, self.w, keyHeight + 1, 1)

        GFX.setColor(self.blackKeyColor)
        self:line(0, keyEnd, self.w - 1, keyEnd, false)

        if keyHeight > self.minKeyHeightToDrawCenterline then
            GFX.setColor(self.keyCenterLineColor)
            local keyCenterLine = self:pitchToPixels(self.pitchHeight - i)
            self:line(0, keyCenterLine, self.w - 1, keyCenterLine, false)
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
    local editCursorPixels = self:timeToPixels(Alk.projects[0].editCursorTime - self.leftEdge)
    local playPositionPixels = self:timeToPixels(Alk.projects[0].playCursorTime - self.leftEdge)
    GFX.setColor(self.editCursorColor)
    self:line(editCursorPixels, 0, editCursorPixels, self.h, false)
    if Alk.projects[0].isPlaying or Alk.projects[0].isRecording then
        GFX.setColor(self.playCursorColor)
        self:line(playPositionPixels, 0, playPositionPixels, self.h, false)
    end
end

---------------------- Events ----------------------

function PitchEditor:onUpdate()
    self.mouseTime = self:pixelsToTime(GFX.mouseX)
    self.prevMouseTime = self:pixelsToTime(GFX.prevMouseX)
    self.mousePitch = self:pixelsToPitch(GFX.mouseY)
    self.prevMousePitch = self:pixelsToPitch(GFX.prevMouseY)
end
function PitchEditor:onResize()
    self.w = GFX.w
    self.h = GFX.h - self.y
    self.view.xScale = self.w
    self.view.yScale = self.h
end
function PitchEditor:onChar(char)
    local charFunction = self.onCharFunctions[char]
    if charFunction then charFunction() end
end
function PitchEditor:onMouseEnter() end
function PitchEditor:onMouseLeave() end
function PitchEditor:onLeftMouseDown() end
function PitchEditor:onLeftMouseUp()
    if not self.leftMouseWasDragged then
        reaper.SetEditCurPos(self.leftEdge + self.mouseTime, false, true)
    end
    Alk.updateArrange()
end
function PitchEditor:onLeftMouseDrag() end
function PitchEditor:onMiddleMouseDown()
    self.view.scroll.xTarget = GFX.mouseX
    self.view.scroll.yTarget = GFX.mouseY
end
function PitchEditor:onMiddleMouseUp() end
function PitchEditor:onMiddleMouseDrag()
    local xChange = GFX.mouseX - GFX.prevMouseX
    local yChange = GFX.mouseY - GFX.prevMouseY

    if GFX.mods["Shift"].isPressed then
        self.view:changeZoom(xChange, yChange, true)
    else
        self.view:changeScroll(xChange, yChange)
    end
end
function PitchEditor:onRightMouseDown() end
function PitchEditor:onRightMouseUp() end
function PitchEditor:onRightMouseDrag() end
function PitchEditor:onMouseWheel(numTicks)
    self.view.scroll.xTarget = GFX.mouseX
    self.view.scroll.yTarget = GFX.mouseY
    if GFX.mods["Control"].isPressed then
        self.view:changeZoom(0.0, numTicks * 55.0, true)
    else
        self.view:changeZoom(numTicks * 55.0, 0.0, true)
    end
end
function PitchEditor:onMouseHWheel(numTicks) end
function PitchEditor:draw()
    self:drawKeyBackgrounds()
    self:drawItemEdges()
    self:drawEditCursor()
    --gfx.a = 1.0
end

PitchEditor.onCharFunctions = {
    ["Left"] = function()
        msg("left")
    end,
    ["Right"] = function()
        msg("right")
    end,
    ["Up"] = function()
        msg("up")
    end,
    ["Down"] = function()
        msg("down")
    end
}

return PitchEditor