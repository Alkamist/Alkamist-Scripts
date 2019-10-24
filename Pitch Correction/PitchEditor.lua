local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ViewAxis =  require("GFX.ViewAxis")
local BoxSelect = require("GFX.BoxSelect")

--==============================================================
--== Local Functions ===========================================
--==============================================================

local function distanceBetweenTwoPoints(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end
local function minimumDistanceBetweenPointAndLineSegment(pointX, pointY, lineX1, lineY1, lineX2, lineY2)
    local A = pointX - lineX1
    local B = pointY - lineY1
    local C = lineX2 - lineX1
    local D = lineY2 - lineY1
    local dotProduct = A * C + B * D
    local lengthSquared = C * C + D * D
    local param = -1
    local xx
    local yy

    if lengthSquared ~= 0 then
        param = dotProduct / lengthSquared
    end

    if param < 0 then
        xx = lineX1
        yy = lineY1
    elseif param > 1 then
        xx = lineX2
        yy = lineY2
    else
        xx = lineX1 + param * C
        yy = lineY1 + param * D
    end

    local dx = pointX - xx
    local dy = pointY - yy

    return math.sqrt(dx * dx + dy * dy)
end
local function nodeIsSelected(node)                return node.isSelected end
local function setNodeSelected(node, shouldSelect) node.isSelected = shouldSelect end
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

--==============================================================
--== Initialization ============================================
--==============================================================

local PitchEditor = {}

function PitchEditor:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.x =     init.x or 0
    self.y =     init.y or 0
    self.w =     init.w or 0
    self.h =     init.h or 0

    self.whiteKeyNumbers =    getWhiteKeyNumbers()
    self.minKeyHeightToDrawCenterline = init.minKeyHeightToDrawCenterline or 16
    self.pitchHeight =        init.pitchHeight        or 128

    self.backgroundColor =    init.backgroundColor    or { 0.2,  0.2,  0.2,  1.0,  0 }
    self.blackKeyColor =      init.blackKeyColor      or { 0.25, 0.25, 0.25, 1.0,  0 }
    self.whiteKeyColor =      init.whiteKeyColor      or { 0.34, 0.34, 0.34, 1.0,  0 }
    self.keyCenterLineColor = init.keyCenterLineColor or { 1.0,  1.0,  1.0,  0.12, 1 }
    self.itemInsideColor =    init.itemInsideColor    or { 1.0,  1.0,  1.0,  0.02, 1 }
    self.itemEdgeColor =      init.itemEdgeColor      or { 1.0,  1.0,  1.0,  0.15, 1 }
    self.editCursorColor =    init.editCursorColor    or { 1.0,  1.0,  1.0,  0.34, 1 }
    self.playCursorColor =    init.playCursorColor    or { 1.0,  1.0,  1.0,  0.2,  1 }
    self.nodeActiveColor =    init.nodeActiveColor    or { 0.3,  0.6,  1.0,  1.0,  0 }
    self.nodeInactiveColor =  init.nodeInactiveColor  or { 1.0,  0.6,  0.3,  1.0,  0 }

    self.nodeCirclePixelRadius = init.nodeCirclePixelRadius or 3

    if init.scaleWithWindow ~= nil then
        self.scaleWithWindow = init.scaleWithWindow
    else
        self.scaleWithWindow = true
    end

    self.track = {}
    self.items = {}
    self.nodes = {}
    self.selectedNodeIndexes = {}
    self.view = {
        x = ViewAxis:new{
            scale = self.w
        },
        y = ViewAxis:new{
            scale = self.h
        }
    }
    self.boxSelect = BoxSelect:new{
        parent = self,
        thingsToSelect = self.nodes
    }

    self.mouseTime  = 0.0
    self.previousMouseTime = 0.0
    self.mouseTimeChange = 0.0
    self.mousePitch = 0.0
    self.previousMousePitch = 0.0
    self.mousePitchChange = 0.0
    self.leftEdge =   0.0
    self.rightEdge =  0.0
    self.timeWidth =  0.0
    self.mouseOverNodeIndex = false
    self.mouseIsOverLine =    false

    return self
end

--==============================================================
--== Helpful Functions =========================================
--==============================================================

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
    return self.view.x.zoom * self.w * (time / self.timeWidth - self.view.x.scroll)
end
function PitchEditor:pixelsToPitch(relativePixels)
    if self.h <= 0 then return 0.0 end
    return self.pitchHeight * (1.0 - (self.view.y.scroll + relativePixels / (self.h * self.view.y.zoom))) - 0.5
end
function PitchEditor:pitchToPixels(pitch)
    if self.pitchHeight <= 0 then return 0 end
    return self.view.y.zoom * self.h * ((1.0 - (0.5 + pitch) / self.pitchHeight) - self.view.y.scroll)
end
function PitchEditor:calculateMouseInformation()
    self.previousMouseTime = self.mouseTime
    self.previousMousePitch = self.mousePitch
    self.mouseTime =  self:pixelsToTime(self.mouseX)
    self.mousePitch = self:pixelsToPitch(self.mouseY)
    self.mouseTimeChange = self.mouseTime - self.previousMouseTime
    self.mousePitchChange = self.mousePitch - self.previousMousePitch
end

--==============================================================
--== Pitch Correction Nodes ====================================
--==============================================================

function PitchEditor:insertThingIntoGroup(group, newThing, stoppingConditionFn)
    local numberInGroup = #group
    if numberInGroup == 0 then
        group[1] = newThing
        return 1
    end

    for i = 1, numberInGroup do
        local thing = group[i]
        if stoppingConditionFn(thing, newThing) then
            table.insert(group, i, newThing)
            return i
        end
    end

    group[numberInGroup + 1] = newThing
    return numberInGroup + 1
end
function PitchEditor:updateSelectedIndexes()
    self.selectedNodeIndexes = {}
    local numberOfNodes = #self.nodes
    for i = 1, numberOfNodes do
        local node = self.nodes[i]
        if node.isSelected then
            self.selectedNodeIndexes[#self.selectedNodeIndexes + 1] = i
        end
    end
end
function PitchEditor:insertNode(newNode)
    newNode.x = self:timeToPixels(newNode.time)
    newNode.y = self:pitchToPixels(newNode.pitch)
    local newIndex = self:insertThingIntoGroup(self.nodes, newNode, function(node, newNode)
        return node.time >= self.mouseTime
    end)

    self:updateSelectedIndexes()

    --local test = ""
    --for _, index in ipairs(self.selectedNodeIndexes) do
    --    test = test .. " " .. tostring(index)
    --end
    --msg(test)
end
function PitchEditor:recalculateNodeCoordinates()
    local numberOfNodes = #self.nodes
    for i = 1, numberOfNodes do
        local node = self.nodes[i]
        node.x = self:timeToPixels(node.time)
        node.y = self:pitchToPixels(node.pitch)
    end
end
function PitchEditor:sortNodes()
    table.sort(self.nodes, function(left, right)
        return left.time < right.time
    end)
    self:updateSelectedIndexes()
end
function PitchEditor:moveSelectedNodesWithMouse()
    local numberOfSelectedNodes = #self.selectedNodeIndexes
    for i = 1, numberOfSelectedNodes do
        local nodeIndex = self.selectedNodeIndexes[i]
        local node = self.nodes[nodeIndex]

        node.x = node.x + self.GFX.mouseXChange
        node.y = node.y + self.GFX.mouseYChange
        node.time = node.time + self.mouseTimeChange
        node.pitch = node.pitch + self.mousePitchChange
    end

    self:sortNodes()
end
function PitchEditor:moveSelectedNodesByCoordinateChange(xChange, yChange)
    local numberOfSelectedNodes = #self.selectedNodeIndexes
    for i = 1, numberOfSelectedNodes do
        local nodeIndex = self.selectedNodeIndexes[i]
        local node = self.nodes[nodeIndex]

        if xChange then
            node.x = node.x + xChange
            node.time = self:pixelsToTime(node.x)
        end
        if yChange then
            node.y = node.y + yChange
            node.pitch = self:pixelsToPitch(node.y)
        end
    end

    self:sortNodes()
end
function PitchEditor:getIndexOfNodeClosestToMouse()
    local numberOfNodes = #self.nodes
    if numberOfNodes < 1 then return nil end

    local node
    local nextNode
    local lowestDistance
    local isLine = false

    for i = 1, numberOfNodes do
        node = self.nodes[i]
        if i < numberOfNodes then nextNode = self.nodes[i + 1] end

        local nodeDistance = distanceBetweenTwoPoints(node.x, node.y, self.mouseX, self.mouseY)
        lowestDistance = lowestDistance or nodeDistance
        local lineDistance = nodeDistance
        if nextNode then
            lineDistance = minimumDistanceBetweenPointAndLineSegment(node.x, node.y, node.x, node.y, nextNode.x, nextNode.y)
        end

        if nodeDistance < lowestDistance then
            lowestDistance = nodeDistance
            lowestDistanceIndex = i
            isLine = false
        end
        if lineDistance < lowestDistance then
            lowestDistance = lineDistance
            lowestDistanceIndex = i
            isLine = true
        end
    end
    return lowestDistanceIndex, isLine
end

--==============================================================
--== Drawing Code ==============================================
--==============================================================

function PitchEditor:drawMainBackground()
    self:setColor(self.backgroundColor)
    self:drawRectangle(0, 0, self.w, self.h, true)
end
function PitchEditor:drawKeyBackgrounds()
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
        self:drawRectangle(0, keyEnd, self.w, keyHeight + 1, true)

        self:setColor(self.blackKeyColor)
        self:drawLine(0, keyEnd, self.w - 1, keyEnd, false)

        if keyHeight > self.minKeyHeightToDrawCenterline then
            local keyCenterLine = self:pitchToPixels(self.pitchHeight - i)

            self:setColor(self.keyCenterLineColor)
            self:drawLine(0, keyCenterLine, self.w - 1, keyCenterLine, false)
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

        self:setColor(self.itemInsideColor)
        self:drawRectangle(leftBoundPixels + 1, 2, boxWidth - 2, boxHeight - 2, true)

        self:setColor(self.itemEdgeColor)
        self:drawRectangle(leftBoundPixels, 1, boxWidth, boxHeight, false)
    end
end
function PitchEditor:drawEditCursor()
    local editCursorPixels =   self:timeToPixels(reaper.GetCursorPosition() - self.leftEdge)
    local playPositionPixels = self:timeToPixels(reaper.GetPlayPosition() - self.leftEdge)

    self:setColor(self.editCursorColor)
    self:drawLine(editCursorPixels, 0, editCursorPixels, self.h, false)

    local playState = reaper.GetPlayState()
    local projectIsPlaying = playState & 1 == 1
    local projectIsRecording = playState & 4 == 4
    if projectIsPlaying or projectIsRecording then
        self:setColor(self.playCursorColor)
        self:drawLine(playPositionPixels, 0, playPositionPixels, self.h, false)
    end
end
function PitchEditor:drawPitchCorrectionNodes()
    local numberOfNodes = #self.nodes
    for i = 1, numberOfNodes do
        local node = self.nodes[i]
        local nextNode = self.nodes[i + 1]

        if node.isActive then
            self:setColor(self.nodeActiveColor)
        else
            self:setColor(self.nodeInactiveColor)
        end

        local normalColor = self.currentColor
        local brightenedColor = {self.currentColor[1] + 0.2, self.currentColor[2] + 0.2, self.currentColor[3] + 0.2, self.currentColor[4]}

        if i == self.mouseOverNodeIndex and not self.mouseIsOverLine then
            self:setColor(brightenedColor)
        end

        self:drawCircle(node.x, node.y, self.nodeCirclePixelRadius, node.isSelected, true)

        if i == self.mouseOverNodeIndex and self.mouseIsOverLine then
            self:setColor(brightenedColor)
        else
            self:setColor(normalColor)
        end

        if node.isActive and nextNode then
            self:drawLine(node.x, node.y, nextNode.x, nextNode.y, true)
        end
    end
end

--==============================================================
--== Events ====================================================
--==============================================================

function PitchEditor:onInit()
    self:updateSelectedItems()
    self:onWindowResize()
    self:calculateMouseInformation()

    local time = self.timeWidth / 2000
    local timeIncrement = time
    for i = 1, 2000 do
        self:insertNode{
            time = time,
            pitch = 20.0 * math.random() + 50,
            isActive = true,
            isSelected = false
        }
        time = time + timeIncrement
    end

    self:sortNodes()
    self:recalculateNodeCoordinates()
end
function PitchEditor:onUpdate()
    if self.isVisible then
        self:calculateMouseInformation()

        --self.mouseOverNodeIndex, self.mouseIsOverLine = self:getIndexOfNodeClosestToMouse()
        --msg(self.mouseOverNodeIndex)
        --msg(self.mouseIsOverLine)
        self:queueRedraw()
    end

    self:updateSelectedItems()
end
function PitchEditor:onWindowResize()
    if self.scaleWithWindow then
        self.w = self.w + self.GFX.wChange
        self.h = self.h + self.GFX.hChange
        self.view.x.scale = self.w
        self.view.y.scale = self.h
    end

    self:recalculateNodeCoordinates()
end
function PitchEditor:onKeyPress()
    local keyPressFunction = self.onKeyPressFunctions[self.GFX.char]
    if keyPressFunction then keyPressFunction() end
end
function PitchEditor:onMouseLeftDown()
    self:insertNode{
        time = self.mouseTime,
        pitch = self.mousePitch,
        isActive = true,
        isSelected = true
    }
end
function PitchEditor:onMouseLeftDrag()
    self:moveSelectedNodesWithMouse()
end
function PitchEditor:onMouseLeftUp()
    if not self.mouseLeftWasDragged then
        reaper.SetEditCurPos(self.leftEdge + self.mouseTime, false, true)
        reaper.UpdateArrange()
    end
end
function PitchEditor:onMouseMiddleDown()
    self.view.x.target = self.mouseX
    self.view.y.target = self.mouseY
end
function PitchEditor:onMouseMiddleDrag()
    if self.GFX.shiftKeyState then
        self.view.x:changeZoom(self.GFX.mouseXChange)
        self.view.y:changeZoom(self.GFX.mouseYChange)
    else
        self.view.x:changeScroll(self.GFX.mouseXChange)
        self.view.y:changeScroll(self.GFX.mouseYChange)
    end

    self:recalculateNodeCoordinates()
end
--function PitchEditor:onMouseMiddleUp()
--end
function PitchEditor:onMouseRightDown()
    self.boxSelect:startSelection(self.mouseX, self.mouseY)
end
function PitchEditor:onMouseRightDrag()
    self.boxSelect:editSelection(self.mouseX, self.mouseY)
end
function PitchEditor:onMouseRightUp()
    self.boxSelect:makeSelection(self.nodes, setNodeSelected, nodeIsSelected, self.GFX.shiftKeyState, self.GFX.controlKeyState)
    self:updateSelectedIndexes()
end
function PitchEditor:onMouseWheel()
    local xSensitivity = 55.0
    local ySensitivity = 55.0

    self.view.x.target = self.mouseX
    self.view.y.target = self.mouseY

    if self.GFX.controlKeyState then
        self.view.y:changeZoom(self.GFX.wheel * ySensitivity)
    else
        self.view.x:changeZoom(self.GFX.wheel * xSensitivity)
    end

    self:recalculateNodeCoordinates()
end
function PitchEditor:onDraw()
    self:drawMainBackground()
    self:drawKeyBackgrounds()
    self:drawItemEdges()
    self:drawEditCursor()
    self:drawPitchCorrectionNodes()
    self.boxSelect:draw()
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