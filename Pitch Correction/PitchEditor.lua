package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GFXChild = require("GFX.GFXChild")
local View = require("GFX.View")

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

function PitchEditor:new(init)
    local init = init or {}
    if init.gfxAPI == nil then return nil end

    local base = GFXChild:new(init)
    local self = setmetatable(base, { __index = self })

    self:setWidth(init.gfxAPI:getWidth())
    self:setHeight(init.gfxAPI:getHeight() - self:getY())
    self._whiteKeyNumbers = getWhiteKeyNumbers()
    self._pitchHeight =        init.maxPitch or 128
    self._blackKeyColor =      {0.25, 0.25, 0.25, 1.0}
    self._whiteKeyColor =      {0.34, 0.34, 0.34, 1.0}
    self._keyCenterLineColor = {1.0, 1.0, 1.0, 0.12}
    self._itemInsideColor =    {1.0, 1.0, 1.0, 0.02}
    self._itemEdgeColor =      {1.0, 1.0, 1.0, 0.1}
    self._editCursorColor =    {1.0, 1.0, 1.0, 0.4}
    self._playCursorColor =    {1.0, 1.0, 1.0, 0.3}
    self._minKeyHeightToDrawCenterline = init.minKeyHeightToDrawCenterline or 16

    self.view = View:new{
        xScale = self:getW(),
        yScale = self:getH()
    }

    self:updateSelectedItems()

    return self
end

function PitchEditor:updateSelectedItems()
    local tracks = Alk:getTracks()
    local topMostSelectedItemTrackNumber = #tracks
    for _, item in ipairs(Alk.getSelectedItems()) do
        topMostSelectedItemTrackNumber = math.min(item:getTrack():getNumber(), topMostSelectedItemTrackNumber)
    end
    self.track = tracks[topMostSelectedItemTrackNumber]
    self.items = self.track:getSelectedItems()
end
function PitchEditor:getLeftEdge()
    if #self.items > 0 then
        return self.items[1]:getLeftEdge()
    end
    return 0.0
end
function PitchEditor:getTimeWidth()
    if #self.items > 0 then
        return self.items[#self.items]:getRightEdge() - self:getLeftEdge()
    end
    return 0.0
end
function PitchEditor:pixelsToTime(xPixels)
    return self:getTimeWidth() * (self.view.scroll.x + xPixels / (self.w * self.view.zoom.x))
end
function PitchEditor:timeToPixels(time)
    return self.view.zoom.x * self.w * (time / self:getTimeWidth() - self.view.scroll.x)
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
    for _, item in ipairs(self.items) do
        local leftBoundTime = item:getLeftEdge() - self:getLeftEdge()
        local rightBoundTime = leftBoundTime + item:getLength()
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
    local editCursorPixels = self:timeToPixels(Alk.getProject():getEditCursorTime() - self:getLeftEdge())
    local playPositionPixels = self:timeToPixels(Alk.getProject():getPlayCursorTime() - self:getLeftEdge())
    GFX.setColor(self.editCursorColor)
    self:line(editCursorPixels, 0, editCursorPixels, self.h, false)
    if Alk.getProject():isPlaying() or Alk.getProject():isRecording() then
        GFX.setColor(self.playCursorColor)
        self:line(playPositionPixels, 0, playPositionPixels, self.h, false)
    end
end

---------------------- Events ----------------------

function PitchEditor:onUpdate()
    self.mouseTime = self:pixelsToTime(self:getRelativeMouseX())
    self.prevMouseTime = self:pixelsToTime(self:getPrevRelativeMouseX())
    self.mousePitch = self:pixelsToPitch(self:getRelativeMouseY())
    self.prevMousePitch = self:pixelsToPitch(self:getPrevRelativeMouseY())
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
function PitchEditor:onMouseLeftButtonDown() end
function PitchEditor:onMouseLeftButtonDrag() end
function PitchEditor:onMouseLeftButtonUp()
    if not self:mouseLeftButtonWasDragged() then
        reaper.SetEditCurPos(self:getLeftEdge() + self.mouseTime, false, true)
    end
    Alk.updateArrange()
end
function PitchEditor:onMouseMiddleButtonDown()
    self.view.scroll.xTarget = self:getRelativeMouseX()
    self.view.scroll.yTarget = self:getRelativeMouseY()
end
function PitchEditor:onMouseMiddleButtonDrag()
    local xChange = GFX.mouse:getXChange()
    local yChange = GFX.mouse:getYChange()

    if GFX.mouse.shift:isPressed() then
        self.view:changeZoom(xChange, yChange, true)
    else
        self.view:changeScroll(xChange, yChange)
    end
end
function PitchEditor:onMouseMiddleButtonUp() end
function PitchEditor:onMouseRightButtonDown() end
function PitchEditor:onMouseRightButtonDrag() end
function PitchEditor:onMouseRightButtonUp() end
function PitchEditor:onMouseWheel(numTicks)
    self.view.scroll.xTarget = self:getRelativeMouseX()
    self.view.scroll.yTarget = self:getRelativeMouseY()
    if GFX.mouse.control:isPressed() then
        self.view:changeZoom(0.0, numTicks * 55.0, true)
    else
        self.view:changeZoom(numTicks * 55.0, 0.0, true)
    end
end
function PitchEditor:onMouseHWheel(numTicks) end
function PitchEditor:draw()
    gfx.setimgdim(27, self.w, self.h)
    gfx.dest = 27
    self:drawKeyBackgrounds()
    self:drawItemEdges()
    self:drawEditCursor()
    --gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs])
    gfx.dest = -1
    gfx.a = 1.0
    gfx.blit(27, 1.0, 0.0, self.x, self.y, self.w, self.h, 0, 0, GFX.w, GFX.h, 0.0, 0.0)
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