local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ViewAxis =  require("GFX.ViewAxis")
local BoxSelect = require("GFX.BoxSelect")

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

local PitchEditor = {}

function PitchEditor:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.GFX = init.GFX
    self.x =   init.x or 0
    self.y =   init.y or 0
    self.w =   init.w or 0
    self.h =   init.h or 0

    self.whiteKeyNumbers =    getWhiteKeyNumbers()
    self.minKeyHeightToDrawCenterline = init.minKeyHeightToDrawCenterline or 16
    self.pitchHeight =        init.pitchHeight        or 128

    self.blackKeyColor =      init.blackKeyColor      or {0.25, 0.25, 0.25, 1.0}
    self.whiteKeyColor =      init.whiteKeyColor      or {0.34, 0.34, 0.34, 1.0}
    self.keyCenterLineColor = init.keyCenterLineColor or {1.0, 1.0, 1.0, 0.12}
    self.itemInsideColor =    init.itemInsideColor    or {1.0, 1.0, 1.0, 0.02}
    self.itemEdgeColor =      init.itemEdgeColor      or {1.0, 1.0, 1.0, 0.17}
    self.editCursorColor =    init.editCursorColor    or {1.0, 1.0, 1.0, 0.4}
    self.playCursorColor =    init.playCursorColor    or {1.0, 1.0, 1.0, 0.3}
    self.nodeActiveColor =    init.nodeActiveColor    or {0.3, 0.6, 1.0, 1.0}
    self.nodeInactiveColor =  init.nodeInactiveColor  or {1.0, 0.6, 0.3, 1.0}

    self.nodeCirclePixelRadius = init.nodeCirclePixelRadius or 3

    self.track = {}
    self.items = {}
    self.nodes = {}
    self.selectedNodes = {}
    self.view = {
        x = ViewAxis:new(),
        y = ViewAxis:new()
    }
    self.boxSelect = BoxSelect:new{
        GFX = self.GFX,
        thingsToSelect = self.nodes
    }

    self.mouseTime  = 0.0
    self.mousePitch = 0.0
    self.leftEdge =   0.0
    self.rightEdge =  0.0
    self.timeWidth =  0.0

    self:updateSelectedItems()
    self:onResize()

    return self
end

function PitchEditor:updateSelectedItems()
    local numberOfSelectedItems = reaper.CountSelectedMediaItems(0)
    local topMostSelectedItemTrackNumber = reaper.CountTracks(0)

    self.items = {}

    for i = 1, numberOfSelectedItems do
        local item =        reaper.GetSelectedMediaItem(0, i - 1)
        local track =       reaper.GetMediaItemTrack(item)
        local trackNumber = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        topMostSelectedItemTrackNumber = math.min(topMostSelectedItemTrackNumber, trackNumber)
    end
    self.track = reaper.GetTrack(0, topMostSelectedItemTrackNumber - 1)

    for i = 1, numberOfSelectedItems do
        local item = reaper.GetSelectedMediaItem(0, i - 1)
        if self.track == reaper.GetMediaItemTrack(item) then
            self.items[#self.items + 1] = item
        end
    end

    local numberOfItems = #self.items
    if numberOfItems > 0 then
        local leftMostItem = self.items[1]
        local rightMostItem = self.items[numberOfItems]
        self.leftEdge =  reaper.GetMediaItemInfo_Value(leftMostItem, "D_POSITION")
        self.rightEdge = reaper.GetMediaItemInfo_Value(rightMostItem, "D_POSITION") + reaper.GetMediaItemInfo_Value(rightMostItem, "D_LENGTH")
        self.timeWidth = self.rightEdge - self.leftEdge;
    else
        self.leftEdge = 0
        self.rightEdge = 0
        self.timeWidth = 0
    end
end

function PitchEditor:pixelsToTime(relativePixels)
    if self.w <= 0 then return 0.0 end
    return self.timeWidth * (self.view.x.scroll + relativePixels / (self.w * self.view.x.zoom))
end
function PitchEditor:timeToPixels(time)
    if self.timeWidth <= 0 then return 0 end
    return self.x + self.view.x.zoom * self.w * (time / self.timeWidth - self.view.x.scroll)
end
function PitchEditor:pixelsToPitch(relativePixels)
    if self.h <= 0 then return 0.0 end
    return self.pitchHeight * (1.0 - (self.view.y.scroll + relativePixels / (self.h * self.view.y.zoom))) - 0.5
end
function PitchEditor:pitchToPixels(pitch)
    if self.pitchHeight <= 0 then return 0 end
    return self.y + self.view.y.zoom * self.h * ((1.0 - (0.5 + pitch) / self.pitchHeight) - self.view.y.scroll)
end

function PitchEditor:insertNode(newNode)
    newNode.x = self:timeToPixels(newNode.time)
    newNode.y = self:pitchToPixels(newNode.pitch)

    local numberOfNodes = #self.nodes

    if numberOfNodes == 0 then
        self.nodes[1] = newNode
        return 1
    end

    for i = 1, numberOfNodes do
        local node = self.nodes[i]
        if node.time >= self.mouseTime then
            table.insert(self.nodes, i, newNode)
            return i
        end
    end

    self.nodes[numberOfNodes + 1] = newNode
    return numberOfNodes + 1
end
--function PitchEditor:editSelectedNodes()
--    local numberOfNodes = #self.nodes
--    for i = 1, numberOfNodes do
--        local node = self.nodes[i]
--
--        node.time =
--    end
--end

---------------------- Drawing Code ----------------------

function PitchEditor:drawKeyBackgrounds()
    local previousKeyEnd = self.y + self:pitchToPixels(self.pitchHeight + 0.5)

    for i = 1, self.pitchHeight do
        local keyEnd = self.y + self:pitchToPixels(self.pitchHeight - i + 0.5)
        local keyHeight = keyEnd - previousKeyEnd

        self.GFX:setColor(self.blackKeyColor)
        for _, value in ipairs(self.whiteKeyNumbers) do
            if i == value then
                self.GFX:setColor(self.whiteKeyColor)
            end
        end
        self.GFX:drawRectangle(self.x, keyEnd, self.w, keyHeight + 1, 1)

        self.GFX:setColor(self.blackKeyColor)
        self.GFX:drawLine(self.x, keyEnd, self.x + self.w - 1, keyEnd, false)

        if keyHeight > self.minKeyHeightToDrawCenterline then
            local keyCenterLine = self.y + self:pitchToPixels(self.pitchHeight - i)

            self.GFX:setColor(self.keyCenterLineColor)
            self.GFX:drawLine(self.x, keyCenterLine, self.x + self.w - 1, keyCenterLine, false)
        end

        previousKeyEnd = keyEnd
    end
end
function PitchEditor:drawItemEdges()
    local numberOfItems = #self.items
    for i = 1, numberOfItems do
        local item = self.items[i]
        local leftBoundTime = reaper.GetMediaItemInfo_Value(item, "D_POSITION") - self.leftEdge
        local rightBoundTime = leftBoundTime + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local leftBoundPixels = self:timeToPixels(leftBoundTime)
        local rightBoundPixels = self:timeToPixels(rightBoundTime)
        local boxWidth = rightBoundPixels - leftBoundPixels
        local boxHeight = self.h - 2

        self.GFX:setColor(self.itemInsideColor)
        self.GFX:drawRectangle(leftBoundPixels + 1, 2, boxWidth - 2, boxHeight - 2, 1)

        self.GFX:setColor(self.itemEdgeColor)
        self.GFX:drawRectangle(leftBoundPixels, 1, boxWidth, boxHeight, 0)
    end
end
function PitchEditor:drawEditCursor()
    local editCursorPixels =   self:timeToPixels(reaper.GetCursorPosition() - self.leftEdge)
    local playPositionPixels = self:timeToPixels(reaper.GetPlayPosition() - self.leftEdge)

    self.GFX:setColor(self.editCursorColor)
    self.GFX:drawLine(editCursorPixels, 0, editCursorPixels, self.h, false)

    local playState = reaper.GetPlayState()
    local projectIsPlaying = playState & 1 == 1
    local projectIsRecording = playState & 4 == 4
    if projectIsPlaying or projectIsRecording then
        self.GFX:setColor(self.playCursorColor)
        self.GFX:drawLine(playPositionPixels, 0, playPositionPixels, self.h, false)
    end
end
function PitchEditor:drawPitchCorrectionNodes()
    local numberOfNodes = #self.nodes
    for i = 1, numberOfNodes do
        local node = self.nodes[i]
        local nextNode = self.nodes[i + 1]

        if node.isActive then
            self.GFX:setColor(self.nodeActiveColor)
        else
            self.GFX:setColor(self.nodeInactiveColor)
        end

        self.GFX:drawCircle(node.x, node.y, self.nodeCirclePixelRadius, node.isSelected, true)

        if node.isActive and nextNode then
            self.GFX:drawLine(node.x, node.y, nextNode.x, nextNode.y, true)
        end
    end
end

---------------------- Events ----------------------

function PitchEditor:onUpdate()
    self.mouseTime =  self:pixelsToTime(self.relativeMouseX)
    self.mousePitch = self:pixelsToPitch(self.relativeMouseY)

    self:updateSelectedItems()
end
function PitchEditor:onResize()
    local newWidth = self.GFX.w - self.x
    local newHeight = self.GFX.h - self.y

    self.w = newWidth
    self.h = newHeight
    self.view.x.scale = newWidth
    self.view.y.scale = newHeight
end
function PitchEditor:onKeyPress()
    local keyPressFunction = self.onKeyPressFunctions[self.GFX.char]
    if keyPressFunction then keyPressFunction() end
end
function PitchEditor:onMouseEnter() end
function PitchEditor:onMouseLeave() end
function PitchEditor:onMouseLeftButtonDown()
    self:insertNode{
        time = self.mouseTime,
        pitch = self.mousePitch,
        isActive = true,
        isSelected = true
    }
end
function PitchEditor:onMouseLeftButtonDrag() end
function PitchEditor:onMouseLeftButtonUp()
    if not self.leftIsDragging then
        reaper.SetEditCurPos(self.leftEdge + self.mouseTime, false, true)
        reaper.UpdateArrange()
    end
end
function PitchEditor:onMouseMiddleButtonDown()
    self.view.x.target = self.relativeMouseX
    self.view.y.target = self.relativeMouseY
end
function PitchEditor:onMouseMiddleButtonDrag()
    if self.GFX.shiftState then
        self.view.x:changeZoom(self.GFX.mouseXChange)
        self.view.y:changeZoom(self.GFX.mouseYChange)
    else
        self.view.x:changeScroll(self.GFX.mouseXChange)
        self.view.y:changeScroll(self.GFX.mouseYChange)
    end
end
function PitchEditor:onMouseMiddleButtonUp() end
function PitchEditor:onMouseRightButtonDown()
    self.boxSelect:startSelection(self.relativeMouseX, self.relativeMouseY)
end
function PitchEditor:onMouseRightButtonDrag()
    self.boxSelect:editSelection(self.relativeMouseX, self.relativeMouseY)
end
function PitchEditor:onMouseRightButtonUp()
    self.boxSelect:makeSelection(self.GFX.shiftState, self.GFX.controlState)
end
function PitchEditor:onMouseWheel()
    local xSensitivity = 55.0
    local ySensitivity = 55.0

    self.view.x.target = self.relativeMouseX
    self.view.y.target = self.relativeMouseY

    if self.GFX.controlState then
        self.view.y:changeZoom(self.GFX.wheel * ySensitivity)
    else
        self.view.x:changeZoom(self.GFX.wheel * xSensitivity)
    end
end
function PitchEditor:onMouseHWheel() end
function PitchEditor:onDraw()
    --local drawBuffer = 27

    --gfx.setimgdim(drawBuffer, width, height)
    --gfx.dest = drawBuffer

    self:drawKeyBackgrounds()
    self:drawItemEdges()
    self:drawEditCursor()
    self:drawPitchCorrectionNodes()
    self.boxSelect:draw()

    --gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs])
    --gfx.dest = -1
    --gfx.a = 1.0
    --gfx.blit(drawBuffer, 1.0, 0.0, x, y, width, height, 0, 0, gfx.w, gfx.h, 0.0, 0.0)
end

PitchEditor.onKeyPressFunctions = {
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