local math = math
local sqrt = math.sqrt
local table = table
local tableInsert = table.insert
local tableSort = table.sort

local function getMinimumDistanceBetweenPointAndLineSegment(pointX, pointY, lineX1, lineY1, lineX2, lineY2)
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

    return sqrt(dx * dx + dy * dy)
end
local function getDistanceBetweenTwoPoints(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return sqrt(dx * dx + dy * dy)
end

local PolyLine = {}

function PolyLine:new()
    local self = self or {}

    local defaults = {}
    defaults.mouseEditPixelRange = 6
    defaults.points = {}
    defaults.glowWhenMouseIsOver = true
    defaults.mouseOverIndex = nil
    defaults.mouseOverDistance = nil
    defaults.mouseIsOverPoint = nil
    defaults.lineColor = { 0.5, 0.5, 0.5, 1, 0 }
    defaults.pointShade = { 1, 1, 1, 0.1, 0 }
    defaults.glowColor = { 1.0, 1.0, 1.0, 0.4, 0 }

    for k, v in pairs(defaults) do if self[k] == nil then self[k] = v end end
    for k, v in pairs(PolyLine) do if self[k] == nil then self[k] = v end end
    return self
end
function PolyLine.sortFn(before, after)
    return before.x < after.x
end
function PolyLine:drawLineFn(point, nextPoint)
    self:drawLine(point.x, point.y, nextPoint.x, nextPoint.y, true)
end
function PolyLine:drawPointFn(point)
    self:drawRectangle(point.x - 1, point.y - 1, 3, 3, true)
end
function PolyLine:updateMouseOverInfo()
    local points = self.points
    local numberOfPoints = #points
    if numberOfPoints < 1 then return end
    local mouseX = self.mouse.x
    local mouseY = self.mouse.y

    local lowestPointDistance
    local closestPointIndex = 1
    local lowestLineDistance
    local closestLineIndex = 1

    for i = 1, numberOfPoints do
        local point = points[i]
        local pointX = point.x
        local pointY = point.y

        local pointDistance = getDistanceBetweenTwoPoints(mouseX, mouseY, pointX, pointY)

        lowestPointDistance = lowestPointDistance or pointDistance
        if pointDistance < lowestPointDistance then
            lowestPointDistance = pointDistance
            closestPointIndex = i
        end

        local nextPoint = points[i + 1]
        if nextPoint then
            local nextPointX = nextPoint.x
            local nextPointY = nextPoint.y

            local lineDistance = getMinimumDistanceBetweenPointAndLineSegment(mouseX, mouseY, pointX, pointY, nextPointX, nextPointY)
            lowestLineDistance = lowestLineDistance or lineDistance
            if lineDistance < lowestLineDistance then
                lowestLineDistance = lineDistance
                closestLineIndex = i
            end
        end
    end

    local mouseOverIndex
    local mouseOverDistance
    local mouseIsOverPoint
    local mouseEditPixelRange = self.mouseEditPixelRange

    if lowestPointDistance < mouseEditPixelRange then
        mouseOverIndex = closestPointIndex
        mouseOverDistance = lowestPointDistance
        mouseIsOverPoint = true

    elseif lowestLineDistance < mouseEditPixelRange then
        mouseOverIndex = closestLineIndex
        mouseOverDistance = lowestLineDistance
        mouseIsOverPoint = false
    end

    self.mouseOverIndex = mouseOverIndex
    self.mouseOverDistance = mouseOverDistance
    self.mouseIsOverPoint = mouseIsOverPoint
end
function PolyLine:handleSelectionLogic()
    local points = self.points
    if self.mouse.buttons.left.justPressed and self.mouseOverIndex then
        self.editPointIndex = self.mouseOverIndex
        self.editPoint = points[self.editPointIndex]

        if not self.keyboard.modifiers.shift.isPressed and not self.editPoint.isSelected then
            for i = 1, #points do
                local point = points[i]
                point.isSelected = false
            end
        end

        self.editPoint.isSelected = true
    end
    if self.mouse.buttons.left.justReleased then
        self.editPointIndex = nil
        self.editPoint = nil
    end
end
function PolyLine:handleMovementLogic()
    local points = self.points
    if self.editPoint and self.mouse.buttons.left.justDragged then
        for i = 1, #points do
            local point = points[i]
            if point.isSelected then
                point.x = point.x + self.mouse.xChange
                point.y = point.y + self.mouse.yChange
            end
        end
        tableSort(points, self.sortFn)
    end
end
function PolyLine:update()
    self:updateMouseOverInfo()
    self:handleSelectionLogic()
    self:handleMovementLogic()
end
function PolyLine:draw()
    local points = self.points
    local drawLineFn = self.drawLineFn
    local drawPointFn = self.drawPointFn
    local lineColor = self.lineColor
    local pointShade = self.pointShade
    local glowColor = self.glowColor
    local mouseOverIndex = self.mouseOverIndex
    local mouseIsOverPoint = self.mouseIsOverPoint
    local glowWhenMouseIsOver = self.glowWhenMouseIsOver
    local setColor = self.setColor

    for i = 1, #points do
        local point = points[i]
        local nextPoint = points[i + 1]
        local pointIsSelected = point.isSelected
        local shouldGlowLine = pointIsSelected or (glowWhenMouseIsOver and mouseOverIndex == i and not mouseIsOverPoint)
        local shouldGlowPoint = pointIsSelected or (glowWhenMouseIsOver and mouseOverIndex == i and mouseIsOverPoint)

        if nextPoint then
            setColor(self, lineColor)
            drawLineFn(self, point, nextPoint)

            if shouldGlowLine then
                setColor(self, glowColor)
                drawLineFn(self, point, nextPoint)
            end
        end

        setColor(self, lineColor)
        drawPointFn(self, point)

        setColor(self, pointShade)
        drawPointFn(self, point)

        if shouldGlowPoint then
            setColor(self, glowColor)
            drawPointFn(self, point)
        end
    end
end

return PolyLine