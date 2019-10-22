local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ViewAxis = require("GFX.ViewAxis")

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

    self.track = {}
    self.items = {}
    self.view = {
        x = ViewAxis:new(),
        y = ViewAxis:new()
    }

    self.mouseTime  = 0.0
    self.mousePitch = 0.0
    self.leftEdge =   0.0
    self.timeWidth =  0.0

    self.numberOfSelectedItems = 0
    self.previousNumberOfSelectedItems = 0

    self:updateSelectedItems()
    self:onResize()

    return self
end

function PitchEditor:updateLeftEdge()
    if #self.items > 0 then
        self.leftEdge:update(self.items[1]:getLeftEdge())
    else
        self.leftEdge:update(0.0)
    end
end
function PitchEditor:updateTimeWidth()
    if #self.items > 0 then
        self.timeWidth:update(self.items[#self.items]:getRightEdge() - self.leftEdge.current)
    else
        self.timeWidth:update(0.0)
    end
end
function PitchEditor:updateSelectedItems()
    --local tracks = Alk:getTracks()
    --local selectedItems = Alk:getSelectedItems()
    --local topMostSelectedItemTrackNumber = #tracks
    --for _, item in ipairs(selectedItems) do
    --    local itemTrackNumber = item:getTrack():getNumber()
    --    topMostSelectedItemTrackNumber = math.min(itemTrackNumber, topMostSelectedItemTrackNumber)
    --end
    --self.track = tracks[topMostSelectedItemTrackNumber]
    --self.items = self.track:getSelectedItems()
    --self:updateLeftEdge()
    --self:updateTimeWidth()
end

function PitchEditor:pixelsToTime(relativePixels)
    return self.timeWidth * (self.view.x.scroll + relativePixels / (self.w * self.view.x.zoom))
end
function PitchEditor:timeToPixels(time)
    return self.x + self.view.x.zoom * self.w * (time / self.timeWidth - self.view.x.scroll)
end
function PitchEditor:pixelsToPitch(relativePixels)
    return self.pitchHeight * (1.0 - (self.view.y.scroll + relativePixels / (self.h * self.view.y.zoom))) - 0.5
end
function PitchEditor:pitchToPixels(pitch)
    return self.y + self.view.y.zoom * self.h * ((1.0 - (0.5 + pitch) / self.pitchHeight) - self.view.y.scroll)
end

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
--[[function PitchEditor:drawItemEdges()
    local height = self.height.current

    for _, item in ipairs(self.items) do
        local leftBoundTime = item:getLeftEdge() - self.leftEdge.current
        local rightBoundTime = leftBoundTime + item:getLength()
        local leftBoundPixels = self:timeToPixels(leftBoundTime)
        local rightBoundPixels = self:timeToPixels(rightBoundTime)
        local boxWidth = rightBoundPixels - leftBoundPixels
        local boxHeight = height - 2

        self:setColor(self.itemInsideColor)
        self:drawRectangle(leftBoundPixels + 1, 2, boxWidth - 2, boxHeight - 2, 1)

        self:setColor(self.itemEdgeColor)
        self:drawRectangle(leftBoundPixels, 1, boxWidth, boxHeight, 0)
    end
end]]--
--[[function PitchEditor:drawEditCursor()
    local project = Alk:getProject()
    local editCursorPixels = self:timeToPixels(project:getEditCursorTime() - self.leftEdge.current)
    local playPositionPixels = self:timeToPixels(project:getPlayCursorTime() - self.leftEdge.current)
    local height = self.height.current

    self:setColor(self.editCursorColor)
    self:drawLine(editCursorPixels, 0, editCursorPixels, height, false)

    if project:isPlaying() or project:isRecording() then
        self:setColor(self.playCursorColor)
        self:drawLine(playPositionPixels, 0, playPositionPixels, height, false)
    end
end]]--

---------------------- Events ----------------------

function PitchEditor:onUpdate()
    self.mouseTime =  self:pixelsToTime(self.relativeMouseX)
    self.mousePitch = self:pixelsToPitch(self.relativeMouseY)

    self.numberOfSelectedItems = reaper.CountSelectedMediaItems(0)
    if self.numberOfSelectedItems ~= self.previousNumberOfSelectedItems then
        self:updateSelectedItems()
    end
    self.previousNumberOfSelectedItems = self.numberOfSelectedItems
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
    --local charFunction = self.onCharFunctions[self.keyboard.char]
    --if charFunction then charFunction() end
end
function PitchEditor:onMouseEnter() end
function PitchEditor:onMouseLeave() end
function PitchEditor:onMouseLeftButtonDown()
    --self:addPitchCorrectionNode(self.relativeMouseX.current, self.relativeMouseY.current)
end
function PitchEditor:onMouseLeftButtonDrag() end
function PitchEditor:onMouseLeftButtonUp()
    --if not self.leftIsDragging then
    --    local project = Alk:getProject()
    --    project:setEditCursorTime(self.leftEdge.current + self.mouseTime.current, false, true)
    --end
    --Alk:updateArrange()
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
    --self.boxSelect:activate(self.relativeMouseX.current, self.relativeMouseY.current)
end
function PitchEditor:onMouseRightButtonDrag()
    --self.boxSelect:edit(self.relativeMouseX.current, self.relativeMouseY.current)
end
function PitchEditor:onMouseRightButtonUp()
    --self.boxSelect:deactivate()
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
    --self:drawItemEdges()
    --self:drawEditCursor()
    --self:drawPitchCorrectionNodes()
    --self.boxSelect:draw()

    --gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs])
    --gfx.dest = -1
    --gfx.a = 1.0
    --gfx.blit(drawBuffer, 1.0, 0.0, x, y, width, height, 0, 0, gfx.w, gfx.h, 0.0, 0.0)
end

--[[PitchEditor.onCharFunctions = {
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
}]]--

return PitchEditor