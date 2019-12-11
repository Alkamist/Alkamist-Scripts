local reaper = reaper
local gfx = gfx
local pairs = pairs
local math = math
local table = table

local MouseButtons = require("MouseButtons")
local Widget = require("Widget")
local BoxSelect = require("BoxSelect")

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
end
local function arrayInsert(t, newThing, sortFn)
    local amount = #t
    if amount == 0 then
        t[1] = newThing
        return 1
    end

    for i = 1, amount do
        local thing = t[i]
        if not sortFn(thing, newThing) then
            table.insert(t, i, newThing)
            return i
        end
    end

    t[amount + 1] = newThing
    return amount + 1
end

local PolyLine = {}

function PolyLine:new(object)
    local object = object or {}
    local defaults = {}

    defaults.points = {}
    defaults.editPointIndex = nil

    local lineColor = { 0.5, 0.5, 0.5, 1, 0 }
    defaults.lineColor = lineColor
    defaults.pointColor = { lineColor[1] + 0.03, lineColor[2] + 0.03, lineColor[3] + 0.03, lineColor[4], lineColor[5] }
    defaults.glowColor = { 1.0, 1.0, 1.0, 0.1, 0 }

    defaults.mouseEditPixelRange = 6
    defaults.glowWhenMouseIsOver = true

    --defaults.drawLineFn = function(self, point, nextPoint) self.line(point.x + self.x, point.y + self.y, nextPoint.x + self.x, nextPoint.y + self.y, true) end
    --defaults.drawPointFn = function(self, point) gfx.rect(point.x + self.x - 1, point.y + self.y - 1, 3, 3, true) end
    defaults.sortFn = function(before, after) return before.x < after.x end

    defaults.boxSelect = BoxSelect.new{
        thingsToSelect = defaults.points,
        selectionControl = MouseButtons.left,
        additiveControl = MouseButtons.shift,
        inversionControl = MouseButtons.control
    }

    for k, v in pairs(defaults) do if object[k] == nil then object[k] = v end end
    for k, v in pairs(self) do if object[k] == nil then object[k] = v end end
    return Widget:new(object)
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
    if MouseButtons.left.justPressed and self.mouseOverIndex then
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

    if MouseButtons.left.justReleased then
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