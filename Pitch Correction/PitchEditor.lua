package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local NumberTracker =       require("Logic.NumberTracker")
local Alk =                 require("API.Alkamist API")
local GFXChild =            require("GFX.GFXChild")
local View =                require("GFX.View")
local BoxSelect =           require("GFX.BoxSelect")
local PitchCorrectionNode = require("Pitch Correction.PitchCorrectionNode")

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

    local base = GFXChild:new(init)
    local self = setmetatable(base, { __index = self })

    self.whiteKeyNumbers =    getWhiteKeyNumbers()
    self.pitchHeight =        init.pitchHeight or 128
    self.blackKeyColor =      {0.25, 0.25, 0.25, 1.0}
    self.whiteKeyColor =      {0.34, 0.34, 0.34, 1.0}
    self.keyCenterLineColor = {1.0, 1.0, 1.0, 0.12}
    self.itemInsideColor =    {1.0, 1.0, 1.0, 0.02}
    self.itemEdgeColor =      {1.0, 1.0, 1.0, 0.1}
    self.editCursorColor =    {1.0, 1.0, 1.0, 0.4}
    self.playCursorColor =    {1.0, 1.0, 1.0, 0.3}
    self.minKeyHeightToDrawCenterline = init.minKeyHeightToDrawCenterline or 16

    self.track = {}
    self.items = {}
    self.pitchCorrectionNodes = {}

    self.view =      View:new()
    self.boxSelect = BoxSelect:new()

    self.mouseTime  = NumberTracker:new(0)
    self.mousePitch = NumberTracker:new(0)
    self.leftEdge =   NumberTracker:new(0)
    self.timeWidth =  NumberTracker:new(0)

    self.numberOfSelectedItems = NumberTracker:new(0)

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
        self.timeWidth:update(self.items[#self.items]:getRightEdge() - self.leftEdge)
    else
        self.timeWidth:update(0.0)
    end
end
function PitchEditor:updateSelectedItems()
    local tracks = Alk:getTracks()
    local selectedItems = Alk:getSelectedItems()
    local topMostSelectedItemTrackNumber = #tracks
    for _, item in ipairs(selectedItems) do
        local itemTrackNumber = item:getTrack():getNumber()
        topMostSelectedItemTrackNumber = math.min(itemTrackNumber, topMostSelectedItemTrackNumber)
    end
    self.track = tracks[topMostSelectedItemTrackNumber]
    self.items = self.track:getSelectedItems()
    self:updateLeftEdge()
    self:updateTimeWidth()
end

function PitchEditor:pixelsToTime(xPixels)
    local scrollX = self.view.scroll.x
    local zoomX = self.view.zoom.x
    local width = self.width
    local timeWidth = self.timeWidth

    return timeWidth * (scrollX + xPixels / (width * zoomX))
end
function PitchEditor:timeToPixels(time)
    local scrollX = self.view.scroll.x
    local zoomX = self.view.zoom.x
    local width = self.width.current
    local timeWidth = self.timeWidth.current

    return zoomX * width * (time / timeWidth - scrollX)
end
function PitchEditor:pixelsToPitch(yPixels)
    local scrollY = self.view.scroll.y
    local zoomY = self.view.zoom.y
    local height = self.height
    local pitchHeight = self.pitchHeight

    return pitchHeight * (1.0 - (scrollY + yPixels / (height * zoomY))) - 0.5
end
function PitchEditor:pitchToPixels(pitch)
    local scrollY = self.view.scroll.y
    local zoomY = self.view.zoom.y
    local height = self.height
    local pitchHeight = self.pitchHeight

    return zoomY * height * ((1.0 - (0.5 + pitch) / pitchHeight) - scrollY)
end

function PitchEditor:addPitchCorrectionNode(x, y)
    --local nextNode = self.pitchCorrectionNodes[#self.pitchCorrectionNodes]
    --local newNode = PitchCorrectionNode:new{
    --    x = x,
    --    y = y,
    --    nextNode = nextNode,
    --    isActive = true
    --}
    --table.insert(self.pitchCorrectionNodes, newNode)
end

---------------------- Drawing Code ----------------------

function PitchEditor:drawKeyBackgrounds()
    local width = self.width.current

    local previousKeyEnd = self:pitchToPixels(self.pitchHeight + 0.5)

    for i = 1, self.pitchHeight do
        local keyEnd = self:pitchToPixels(self.pitchHeight - i + 0.5)
        local keyHeight = keyEnd - previousKeyEnd

        self:setColor(self.blackKeyColor)
        for _, value in ipairs(self.whiteKeyNumbers) do
            if i == value then
                self:setColor(self.whiteKeyColor)
            end
        end
        self:drawRectangle(0, keyEnd, width, keyHeight + 1, 1)

        self:setColor(self.blackKeyColor)
        self:drawLine(0, keyEnd, width - 1, keyEnd, false)

        if keyHeight > self.minKeyHeightToDrawCenterline then
            local keyCenterLine = self:pitchToPixels(self.pitchHeight - i)

            self:setColor(self.keyCenterLineColor)
            self:drawLine(0, keyCenterLine, width - 1, keyCenterLine, false)
        end

        previousKeyEnd = keyEnd
    end
end
function PitchEditor:drawItemEdges()
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
end
function PitchEditor:drawEditCursor()
    local project = Alk:getProject()
    local editCursorPixels = self:timeToPixels(project:getEditCursorTime() - self.leftEdge)
    local playPositionPixels = self:timeToPixels(project:getPlayCursorTime() - self.leftEdge)
    local height = self.height.current

    self:setColor(self.editCursorColor)
    self:drawLine(editCursorPixels, 0, editCursorPixels, height, false)

    if project:isPlaying() or project:isRecording() then
        self:setColor(self.playCursorColor)
        self:drawLine(playPositionPixels, 0, playPositionPixels, height, false)
    end
end
function PitchEditor:drawPitchCorrectionNodes()
    --for _, node in ipairs(self.pitchCorrectionNodes) do
    --    node:draw()
    --end
end

---------------------- Events ----------------------

function PitchEditor:onUpdate()
    self.mouseTime:update(self:pixelsToTime(self.relativeMouseX.current))
    self.mousePitch:update(self:pixelsToPitch(self.relativeMouseY.current))

    self.numberOfSelectedItems:update(#Alk:getSelectedItems())
    if self.numberOfSelectedItems.changed then
        self:updateSelectedItems()
    end
end
function PitchEditor:onResize()
    local newWidth = self.GFX.width.current
    local newHeight = self.GFX.height.current - self.y.current

    self.width:update(newWidth)
    self.height:update(newHeight)
    self.view.xScale = newWidth
    self.view.yScale = newHeight
end
function PitchEditor:onKeyPress()
    local charFunction = self.onCharFunctions[self.keyboard.char]
    if charFunction then charFunction() end
end
function PitchEditor:onMouseEnter() end
function PitchEditor:onMouseLeave() end
function PitchEditor:onMouseLeftButtonDown()
    --self:addPitchCorrectionNode(self.relativeMouseX.current, self.relativeMouseY)
end
function PitchEditor:onMouseLeftButtonDrag() end
function PitchEditor:onMouseLeftButtonUp()
    if not self.leftIsDragging then
        local project = Alk:getProject()
        project:setEditCursorTime(self.leftEdge + self.mouseTime, false, true)
    end
    Alk:updateArrange()
end
function PitchEditor:onMouseMiddleButtonDown()
    self.view.scroll.xTarget = self.relativeMouseX.current
    self.view.scroll.yTarget = self.relativeMouseY.current
end
function PitchEditor:onMouseMiddleButtonDrag()
    local xChange = self.mouse.x.delta
    local yChange = self.mouse.y.delta
    local shiftIsPressed = self.mouse.modifiers.shift.state.current

    if shiftIsPressed then
        self.view:changeZoom(xChange, yChange, true)
    else
        self.view:changeScroll(xChange, yChange)
    end
end
function PitchEditor:onMouseMiddleButtonUp() end
function PitchEditor:onMouseRightButtonDown()
    self.boxSelect:activate(self.relativeMouseX.current, self.relativeMouseY.current)
end
function PitchEditor:onMouseRightButtonDrag()
    self.boxSelect:edit(self.relativeMouseX.current, self.relativeMouseY.current)
end
function PitchEditor:onMouseRightButtonUp()
    self.boxSelect:deactivate()
end
function PitchEditor:onMouseWheel()
    local numTicks = self.mouse.wheel
    local controlIsPressed = self.mouse.modifiers.control.state.current
    local xSensitivity = 55.0
    local ySensitivity = 55.0

    self.view.scroll.xTarget = self.relativeMouseX.current
    self.view.scroll.yTarget = self.relativeMouseY.current

    if controlIsPressed then
        self.view:changeZoom(0.0, numTicks * ySensitivity, true)
    else
        self.view:changeZoom(numTicks * xSensitivity, 0.0, true)
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