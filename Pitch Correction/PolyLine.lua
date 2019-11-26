local reaper = reaper
local gfx = gfx
local pairs = pairs
local math = math
local table = table

local Fn = require("Fn")
local Widget = require("Widget")
local BoxSelect = require("BoxSelect")
local GUI = require("GUI")
local mouse = GUI.mouse
local keyboard = GUI.keyboard
local leftMouseButton = mouse.buttons.left
local rightMouseButton = mouse.buttons.right
local shiftKey = keyboard.modifiers.shift
local controlKey = keyboard.modifiers.control

local PolyLine = {}
function PolyLine.new(object)
    local self = {}

    self.x = 0
    self.y = 0
    self.points = {}
    self.editPointIndex = nil

    local lineColor = { 0.5, 0.5, 0.5 }
    self.lineColor = lineColor
    self.pointColor = Fn.addColor(lineColor, 0.03)
    self.glowColor = { 1.0, 1.0, 1.0 }

    self.mouseEditPixelRange = 6
    self.glowWhenMouseIsOver = true

    self.drawLineFn = function(self, point, nextPoint) gfx.line(point.x + self.x, point.y + self.y, nextPoint.x + self.x, nextPoint.y + self.y, true) end
    self.drawPointFn = function(self, point) gfx.rect(point.x + self.x - 1, point.y + self.y - 1, 3, 3, true) end
    self.sortFn = function(before, after) return before.x < after.x end

    local function _getX(self) return self.x end
    local function _getY(self) return self.y end
    self.boxSelect = BoxSelect.new{
        thingsToSelect = self.points,
        selectionControl = rightMouseButton,
        additiveControl = shiftKey,
        inversionControl = controlKey,
        thingIsInside = function(box, thing)
            return box:pointIsInside(thing.x + _getX(object), thing.y + _getY(object))
        end
    }

    return Widget.new(Fn.makeNew(self, PolyLine, object))
end
function PolyLine:insertPoint(point)
    Fn.arrayInsert(self.points, point, self.sortFn)
end
function PolyLine:moveSelectedPointsWithMouse()
    local points = self.points
    local mouseXChange = mouse.xChange
    local mouseYChange = mouse.yChange
    for i = 1, #points do
        local point = points[i]
        if point.isSelected then
            point.x = point.x + mouseXChange
            point.y = point.y + mouseYChange
        end
    end
end
function PolyLine:unselectAllPoints()
    local points = self.points
    for i = 1, #points do
        local point = points[i]
        point.isSelected = false
    end
end
function PolyLine:sortPoints()
    table.sort(self.points, self.sortFn)
end
function PolyLine:update()
    Widget.update(self)
    self.boxSelect:update()

    self.mouseOverIndex, self.mouseIsOverPoint = Fn.getIndexOfPointOrSegmentClosestToPointWithinDistance(self.points, "x", "y", mouse.x - self.x, mouse.y - self.y, self.mouseEditPixelRange)

    local editPoint = nil
    if leftMouseButton.justPressed and self.mouseOverIndex then
        self.editPointIndex = self.mouseOverIndex
        editPoint = self.points[self.editPointIndex]

        if not editPoint.isSelected and not self.boxSelect.additiveControl.isPressed then
            self:unselectAllPoints()
        end

        editPoint.isSelected = true
        if not self.mouseIsOverPoint then
            self.points[self.editPointIndex + 1].isSelected = true
        end
    end

    if self.editPointIndex and mouse.justMoved then
        self:moveSelectedPointsWithMouse()
        self:sortPoints()
    end

    if leftMouseButton.justReleased then
        self.editPointIndex = nil
    end
end
function PolyLine:draw()
    local setColor = Fn.setColor
    local drawLineFn = self.drawLineFn
    local drawPointFn = self.drawPointFn
    local lineColor = self.lineColor
    local pointColor = self.pointColor
    local glowColor = self.glowColor
    local mouseOverIndex = self.mouseOverIndex
    local mouseIsOverPoint = self.mouseIsOverPoint
    local glowWhenMouseIsOver = self.glowWhenMouseIsOver
    local points = self.points

    for i = 1, #points do
        local point = points[i]
        local nextPoint = points[i + 1]
        local pointIsSelected = point.isSelected
        local shouldGlowLine = pointIsSelected or (glowWhenMouseIsOver and mouseOverIndex == i and not mouseIsOverPoint)
        local shouldGlowPoint = pointIsSelected or (glowWhenMouseIsOver and mouseOverIndex == i and mouseIsOverPoint)

        if nextPoint then
            setColor(lineColor)
            drawLineFn(self, point, nextPoint)

            if shouldGlowLine then
                setColor(glowColor)
                drawLineFn(self, point, nextPoint)
            end
        end

        setColor(pointColor)
        drawPointFn(self, point)

        if shouldGlowPoint then
            setColor(glowColor)
            drawPointFn(self, point)
        end
    end

    self.boxSelect:draw()
end
function PolyLine:endUpdate()
    Widget.endUpdate(self)
    self.boxSelect:endUpdate()
end

return PolyLine