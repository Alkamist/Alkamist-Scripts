package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Alk = require("API.Alkamist API")

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

    self:onResize()
    self._whiteKeyNumbers = getWhiteKeyNumbers()
    self._pitchHeight =        init.pitchHeight or 128
    self._blackKeyColor =      {0.25, 0.25, 0.25, 1.0}
    self._whiteKeyColor =      {0.34, 0.34, 0.34, 1.0}
    self._keyCenterLineColor = {1.0, 1.0, 1.0, 0.12}
    self._itemInsideColor =    {1.0, 1.0, 1.0, 0.02}
    self._itemEdgeColor =      {1.0, 1.0, 1.0, 0.1}
    self._editCursorColor =    {1.0, 1.0, 1.0, 0.4}
    self._playCursorColor =    {1.0, 1.0, 1.0, 0.3}
    self._minKeyHeightToDrawCenterline = init.minKeyHeightToDrawCenterline or 16

    self._view = View:new{
        xScale = self:getWidth(),
        yScale = self:getHeight()
    }

    self:updateSelectedItems()

    return self
end

function PitchEditor:getItems()      return self._items end
function PitchEditor:getTrack()      return self._track end
function PitchEditor:getView()       return self._view end
function PitchEditor:getMouseTime()
    local mouse = self:getMouse()
    local relativeMouseX = mouse:getX() - self:getX()
    return self:pixelsToTime(relativeMouseX)
end

function PitchEditor:setItems(items) self._items = items end
function PitchEditor:setTrack(track) self._track = track end

function PitchEditor:updateSelectedItems()
    local tracks = Alk:getTracks()
    local selectedItems = Alk:getSelectedItems()
    local topMostSelectedItemTrackNumber = #tracks
    for _, item in ipairs(selectedItems) do
        local itemTrackNumber = item:getTrack():getNumber()
        topMostSelectedItemTrackNumber = math.min(itemTrackNumber, topMostSelectedItemTrackNumber)
    end
    local track = tracks[topMostSelectedItemTrackNumber]
    self:setTrack(track)
    self:setItems(track:getSelectedItems())
end
function PitchEditor:getLeftEdge()
    local items = self:getItems()
    if #items > 0 then
        return items:getLeftEdge()
    end
    return 0.0
end
function PitchEditor:getTimeWidth()
    local items = self:getItems()
    if #items > 0 then
        return items[#items]:getRightEdge() - self:getLeftEdge()
    end
    return 0.0
end
function PitchEditor:getPitchHeight() return self_pitchHeight end
function PitchEditor:pixelsToTime(xPixels)
    local view = self:getView()
    local scrollX = view:getScrollX()
    local zoomX = view:getZoomX()
    local width = self:getWidth()
    local timeWidth = self:getTimeWidth()

    return timeWidth * (scrollX + xPixels / (width * zoomX))
end
function PitchEditor:timeToPixels(time)
    local view = self:getView()
    local scrollX = view:getScrollX()
    local zoomX = view:getZoomX()
    local width = self:getWidth()
    local timeWidth = self:getTimeWidth()

    return zoomX * width * (time / timeWidth - scrollX)
end
function PitchEditor:pixelsToPitch(yPixels)
    local view = self:getView()
    local scrollY = view:getScrollY()
    local zoomY = view:getZoomY()
    local height = self:getHeight()
    local pitchHeight = self:getPitchHeight()

    return pitchHeight * (1.0 - (scrollY + yPixels / (height * zoomY))) - 0.5
end
function PitchEditor:pitchToPixels(pitch)
    local view = self:getView()
    local scrollY = view:getScrollY()
    local zoomY = view:getZoomY()
    local height = self:getHeight()
    local pitchHeight = self:getPitchHeight()

    return zoomY * height * ((1.0 - (0.5 + pitch) / pitchHeight) - scrollY)
end

---------------------- Drawing Code ----------------------

function PitchEditor:drawKeyBackgrounds()
    local pitchHeight = self:getPitchHeight()
    local blackKeyColor = self._blackKeyColor
    local whiteKeyColor = self._whiteKeyColor
    local keyCenterLineColor = self._keyCenterLineColor
    local minCenterLineHeight = self._minKeyHeightToDrawCenterline
    local whiteKeyNumbers = self._whiteKeyNumbers
    local width = self:getWidth()
    local previousKeyEnd = self:pitchToPixels(pitchHeight + 0.5)

    for i = 1, pitchHeight do
        local keyEnd = self:pitchToPixels(pitchHeight - i + 0.5)
        local keyHeight = keyEnd - previousKeyEnd

        GFX.setColor(blackKeyColor)
        for _, value in ipairs(whiteKeyNumbers) do
            if i == value then
                GFX.setColor(whiteKeyColor)
            end
        end
        self:rect(0, keyEnd, width, keyHeight + 1, 1)

        GFX.setColor(blackKeyColor)
        self:line(0, keyEnd, width - 1, keyEnd, false)

        if keyHeight > minCenterLineHeight then
            local keyCenterLine = self:pitchToPixels(pitchHeight - i)

            GFX.setColor(keyCenterLineColor)
            self:line(0, keyCenterLine, width - 1, keyCenterLine, false)
        end

        previousKeyEnd = keyEnd
    end
end
function PitchEditor:drawItemEdges()
    local itemInsideColor = self._itemInsideColor
    local itemEdgeColor = self._itemEdgeColor
    local height = self:getHeight()
    local items = self:getItems()
    local leftEdge = self:getLeftEdge()

    for _, item in ipairs(items) do
        local leftBoundTime = item:getLeftEdge() - leftEdge
        local rightBoundTime = leftBoundTime + item:getLength()
        local leftBoundPixels = self:timeToPixels(leftBoundTime)
        local rightBoundPixels = self:timeToPixels(rightBoundTime)
        local boxWidth = rightBoundPixels - leftBoundPixels
        local boxHeight = height - 2

        GFX.setColor(itemInsideColor)
        self:rect(leftBoundPixels + 1, 2, boxWidth - 2, boxHeight - 2, 1)

        GFX.setColor(itemEdgeColor)
        self:rect(leftBoundPixels, 1, boxWidth, boxHeight, 0)
    end
end
function PitchEditor:drawEditCursor()
    local project = Alk:getProject()
    local editCursorTime = project:getEditCursorTime()
    local playCursorTime = project:getPlayCursorTime()
    local projectIsPlaying = project:isPlaying()
    local projectIsRecording = project:isRecording()
    local leftEdge = self:getLeftEdge()
    local editCursorPixels = self:timeToPixels(editCursorTime - leftEdge)
    local playPositionPixels = self:timeToPixels(playCursorTime - leftEdge)
    local height = self:getHeight()
    local editCursorColor = self._editCursorColor
    local playCursorColor = self._playCursorColor

    GFX.setColor(editCursorColor)
    self:line(editCursorPixels, 0, editCursorPixels, height, false)

    if projectIsPlaying or projectIsRecording then
        GFX.setColor(playCursorColor)
        self:line(playPositionPixels, 0, playPositionPixels, height, false)
    end
end

---------------------- Events ----------------------

function PitchEditor:onUpdate() end
function PitchEditor:onResize()
    local view = self:getView()
    local gfxAPI = self:getGFXAPI()
    local newWidth = gfxAPI:getWidth()
    local newHeight = gfxAPI:getHeight() - self:getY()

    self:setWidth(newWidth)
    self:setHeight(newHeight)
    view:setXScale(newWidth)
    view:setYScale(newHeight)
end
function PitchEditor:onChar(char)
    local charFunction = self._onCharFunctions[char]
    if charFunction then charFunction() end
end
function PitchEditor:onMouseEnter() end
function PitchEditor:onMouseLeave() end
function PitchEditor:onMouseLeftButtonDown() end
function PitchEditor:onMouseLeftButtonDrag() end
function PitchEditor:onMouseLeftButtonUp()
    local wasDragged = self:isLeftDragging()
    local leftEdge = self:getLeftEdge()
    local mouseTime = self:getMouseTime()

    if not wasDragged then
        local project = Alk:getProject()
        project:setEditCursorTime(leftEdge + mouseTime, false, true)
    end

    Alk:updateArrange()
end
function PitchEditor:onMouseMiddleButtonDown()
    local view = self:getView()
    local mouse = self:getMouse()
    local relativeMouseX = mouse:getX() - self:getX()
    local relativeMouseY = mouse:getY() - self:getY()

    view:setScrollXTarget(relativeMouseX)
    view:setScrollYTarget(relativeMouseY)
end
function PitchEditor:onMouseMiddleButtonDrag()
    local view = self:getView()
    local mouse = self:getMouse()
    local xChange = mouse:getXChange()
    local yChange = mouse:getYChange()
    local shiftIsPressed = mouse:getModifiers().shift:isPressed()

    if shiftIsPressed then
        view:changeZoom(xChange, yChange, true)
    else
        view:changeScroll(xChange, yChange)
    end
end
function PitchEditor:onMouseMiddleButtonUp() end
function PitchEditor:onMouseRightButtonDown() end
function PitchEditor:onMouseRightButtonDrag() end
function PitchEditor:onMouseRightButtonUp() end
function PitchEditor:onMouseWheel(numTicks)
    local view = self:getView()
    local mouse = self:getMouse()
    local relativeMouseX = mouse:getX() - self:getX()
    local relativeMouseY = mouse:getY() - self:getY()
    local controlIsPressed = mouse:getModifiers().control:isPressed()
    local xSensitivity = 55.0
    local ySensitivity = 55.0

    view:setScrollXTarget(relativeMouseX)
    view:setScrollYTarget(relativeMouseY)

    if controlIsPressed then
        view:changeZoom(0.0, numTicks * ySensitivity, true)
    else
        view:changeZoom(numTicks * xSensitivity, 0.0, true)
    end
end
function PitchEditor:onMouseHWheel(numTicks) end
function PitchEditor:draw()
    local x = self:getX()
    local y = self:getY()
    local width = self:getWidth()
    local height = self:getHeight()
    local drawBuffer = 27

    gfx.setimgdim(drawBuffer, width, height)
    gfx.dest = drawBuffer

    self:drawKeyBackgrounds()
    self:drawItemEdges()
    self:drawEditCursor()

    --gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs])
    gfx.dest = -1
    gfx.a = 1.0
    gfx.blit(drawBuffer, 1.0, 0.0, x, y, width, height, 0, 0, gfx.w, gfx.h, 0.0, 0.0)
end

PitchEditor._onCharFunctions = {
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