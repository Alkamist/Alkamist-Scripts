local reaper = reaper
local math = math
local table = table

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Widget = require("GUI.Widget")
local BoxSelect = require("GUI.BoxSelect")

local function arrayRemove(t, fn)
    local n = #t
    local j = 1
    for i = 1, n do
        if not fn(i, j) then
            if i ~= j then
                t[j] = t[i]
                t[i] = nil
            end
            j = j + 1
        else
            t[i] = nil
        end
    end
    return t
end
local function minimumDistanceBetweenPointAndLineSegment(pointX, pointY, lineX1, lineY1, lineX2, lineY2)
    if pointX == nil or pointY == nil or lineX1 == nil or lineY1 == nil or lineX2 == nil or lineY2 == nil then
        return 0.0
    end
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
local function distanceBetweenTwoPoints(x1, y1, x2, y2)
    if x1 == nil or y1 == nil or x2 == nil or y2 == nil then
        return 0.0
    end
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end
local function getIndexAndDistanceOfSegmentClosestToPoint(points, x, y)
    local numberOfPoints = #points
    if numberOfPoints < 1 then return nil end

    local lowestDistance
    local lowestDistanceIndex = 1

    for i = 1, numberOfPoints do
        local point = points[i]
        local nextPoint = points[i + 1]

        local distance
        if nextPoint then
            distance = minimumDistanceBetweenPointAndLineSegment(x, y, point.x, point.y, nextPoint.x, nextPoint.y)
        end
        lowestDistance = lowestDistance or distance

        if distance and distance < lowestDistance then
            lowestDistance = distance
            lowestDistanceIndex = i
        end
    end

    return lowestDistanceIndex, lowestDistance
end
local function getIndexAndDistanceOfPointClosestToPoint(points, x, y)
    local numberOfPoints = #points
    if numberOfPoints < 1 then return nil end

    local lowestDistance
    local lowestDistanceIndex = 1

    for i = 1, numberOfPoints do
        local point = points[i]

        local distance = distanceBetweenTwoPoints(x, y, point.x, point.y)
        lowestDistance = lowestDistance or distance

        if distance and distance < lowestDistance then
            lowestDistance = distance
            lowestDistanceIndex = i
        end
    end

    return lowestDistanceIndex, lowestDistance
end
local function getIndexOfPointOrSegmentClosestToPointWithinDistance(points, x, y, distance)
    local index
    local indexIsPoint
    local segmentIndex, segmentDistance = getIndexAndDistanceOfSegmentClosestToPoint(points, x, y)
    local pointIndex, pointDistance = getIndexAndDistanceOfPointClosestToPoint(points, x, y)
    local pointIsClose = false
    local segmentIsClose = false

    if pointDistance then pointIsClose = pointDistance <= distance end
    if segmentDistance then segmentIsClose = segmentDistance <= distance end

    if pointIsClose or segmentIsClose then
        if segmentIsClose then
            index = segmentIndex
            indexIsPoint = false
        end
        if pointIsClose then
            index = pointIndex
            indexIsPoint = true
        end
    end
    return index, indexIsPoint
end
local function insertThingIntoGroup(group, newThing, stoppingConditionFn)
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

local EditablePolyLine = {}
function EditablePolyLine:new(object)
    local self = Widget:new(self)

    self.points = {}

    local lineColor = { 0.5, 0.5, 0.5, 1.0, 0 }
    self.lineColor = lineColor
    self.pointColor = { lineColor[1] + 0.03, lineColor[2] + 0.03, lineColor[3] + 0.03, lineColor[4], lineColor[5] }
    self.glowColor = { 1.0, 1.0, 1.0, 0.3, 1 }

    self.mouseEditPixelRange = 7
    self.glowWhenMouseOver = true

    self.boxSelect = BoxSelect:new{
        thingsToSelect = self.points
    }

    if object then for k, v in pairs(object) do self[k] = v end end
    return self
end

function EditablePolyLine:insertPoint(point)
    local newPointIndex = insertThingIntoGroup(self.points, point, function(pointInLoop, pointToInsert)
        return pointInLoop.x >= pointToInsert.x
    end)
    return newPointIndex
end
function EditablePolyLine:sortPoints()
    table.sort(self.points, function(left, right)
        return left.x < right.x
    end)
end
function EditablePolyLine:moveSelectedPointsWithMouse()
    local GUI = self.GUI
    local mouseXChange = GUI.mouseXChange
    local mouseYChange = GUI.mouseYChange
    local points = self.points
    for i = 1, #points do
        local point = points[i]
        if point.isSelected then
            point.x = point.x + mouseXChange
            point.y = point.y + mouseYChange
        end
    end
    self:queueRedraw()
end
function EditablePolyLine:setPointSelected(point, shouldSelect)
    point.isSelected = shouldSelect
    self:queueRedraw()
end
function EditablePolyLine:unselectAllPoints()
    local points = self.points
    for i = 1, #points do
        local point = points[i]
        point.isSelected = false
    end
    self:queueRedraw()
end
function EditablePolyLine:handleRightMouseButtonJustPressed()
    self.boxSelect:startSelection(self.relativeMouseX, self.relativeMouseY)
end
function EditablePolyLine:handleRightMouseButtonJustDragged()
    self.boxSelect:editSelection(self.relativeMouseX, self.relativeMouseY)
    self:queueRedraw()
end
function EditablePolyLine:handleRightMouseButtonJustReleased(shouldAddToSelection, shouldInvertSelection)
    self.boxSelect:makeSelection{
        shouldAdd = shouldAddToSelection,
        shouldInvert = shouldInvertSelection
    }
    self:queueRedraw()
end
function EditablePolyLine:handleLeftMouseButtonJustPressed(shouldAddToSelection)
    local mouseOverIndex = self.mouseOverIndex

    if mouseOverIndex then
        local point = self.points[mouseOverIndex]
        local nextPoint = self.points[mouseOverIndex + 1]
        local mouseIsOverPoint = self.mouseIsOverPoint

        if not point.isSelected and not shouldAddToSelection then
            self:unselectAllPoints()
        end

        point.isSelected = true
        self.editPointIndex = mouseOverIndex

        if nextPoint and not mouseIsOverPoint then
            nextPoint.isSelected = true
        end

        self:queueRedraw()
    end
end
function EditablePolyLine:handleLeftMouseButtonJustDragged()
    local editPointIndex = self.editPointIndex

    if editPointIndex then
        self:moveSelectedPointsWithMouse()
        self:sortPoints()
        self:queueRedraw()
    end
end
function EditablePolyLine:handleLeftMouseButtonJustReleased()
    self.editPointIndex = nil
end
function EditablePolyLine:handleDrawLine(point, nextPoint)
    self:drawLine(point.x, point.y, nextPoint.x, nextPoint.y, true)
end
function EditablePolyLine:handleDrawPoint(point)
    self:drawRectangle(point.x - 1, point.y - 1, 3, 3, true)
end

function EditablePolyLine:update()
    local GUI = self.GUI
    local leftMouseButton = GUI.leftMouseButton
    local rightMouseButton = GUI.rightMouseButton
    local shiftKey = GUI.shiftKey
    local controlKey = GUI.controlKey

    self.mouseOverIndex, self.mouseIsOverPoint = getIndexOfPointOrSegmentClosestToPointWithinDistance(self.points, self.relativeMouseX, self.relativeMouseY, self.mouseEditPixelRange)

    if rightMouseButton:justPressedWidget(self) then
        self:handleRightMouseButtonJustPressed()
    end
    if rightMouseButton:justDraggedWidget(self) then
        self:handleRightMouseButtonJustDragged()
    end
    if rightMouseButton:justReleasedWidget(self) then
        self:handleRightMouseButtonJustReleased(shiftKey.isPressed, controlKey.isPressed)
    end
    if leftMouseButton:justPressedWidget(self) then
        self:handleLeftMouseButtonJustPressed(shiftKey.isPressed)
    end
    if leftMouseButton:justDraggedWidget(self) then
        self:handleLeftMouseButtonJustDragged()
    end
    if leftMouseButton:justReleasedWidget(self) then
        self:handleLeftMouseButtonJustReleased()
    end

    if self.mouseOverIndex and self.glowWhenMouseOver then
        self:queueRedraw()
    end
end
function EditablePolyLine:draw()
    local setColor = self.setColor
    local handleDrawLine = self.handleDrawLine
    local handleDrawPoint = self.handleDrawPoint
    local lineColor = self.lineColor
    local pointColor = self.pointColor
    local glowColor = self.glowColor
    local mouseOverIndex = self.mouseOverIndex
    local mouseIsOverPoint = self.mouseIsOverPoint
    local glowWhenMouseOver = self.glowWhenMouseOver
    local points = self.points
    for i = 1, #points do
        local point = points[i]
        local nextPoint = points[i + 1]
        local shouldGlowLine = point.isSelected or (glowWhenMouseOver and mouseOverIndex == i and not mouseIsOverPoint)
        local shouldGlowPoint = point.isSelected or (glowWhenMouseOver and mouseOverIndex == i and mouseIsOverPoint)

        if nextPoint then
            setColor(self, lineColor)
            handleDrawLine(self, point, nextPoint)

            if shouldGlowLine then
                setColor(self, glowColor)
                handleDrawLine(self, point, nextPoint)
            end
        end

        setColor(self, pointColor)
        handleDrawPoint(self, point)

        if shouldGlowPoint then
            setColor(self, glowColor)
            handleDrawPoint(self, point)
        end
    end

    local boxSelect = self.boxSelect
    local boxSelectX = boxSelect.x
    local boxSelectY = boxSelect.y
    local boxSelectWidth = boxSelect.width
    local boxSelectHeight = boxSelect.height
    if boxSelect.isActive then
        self:setColor(boxSelect.edgeColor)
        self:drawRectangle(boxSelectX, boxSelectY, boxSelectWidth, boxSelectHeight, false)

        self:setColor(boxSelect.insideColor)
        self:drawRectangle(boxSelectX + 1, boxSelectY + 1, boxSelectWidth - 2, boxSelectHeight - 2, true)
    end
end

return EditablePolyLine