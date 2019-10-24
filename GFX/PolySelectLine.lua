package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local PolyLine = require("GFX.PolyLine")

--==============================================================
--== Point =====================================================
--==============================================================

local Point = {}

function Point:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.x =             init.x             or 0
    self.y =             init.y             or 0
    self.r =             init.r             or 3
    self.activeColor =   init.activeColor   or { 0.7, 0.7, 0.7, 1.0, 0 }
    self.selectedColor = init.selectedColor or { 0.4, 0.4, 0.4, 1.0, 0 }
    self.parent =        init.parent
    if init.isActive ~= nil then self.isActive = init.isActive else self.isActive = true end
    if init.isSelected ~= nil then self.isSelected = init.isSelected else self.isSelected = true end
end

function Point:getDistanceTo(fromX, fromY)
    local dx = self.x - fromX
    local dy = self.y - fromY
    return math.sqrt(dx * dx + dy * dy)
end

function Point:draw()
    local currentColor
    if self.isActive then
        currentColor = self.activeColor
        self.parent:setColor(currentColor)
    else
        currentColor = self.inactiveColor
        self.parent:setColor(currentColor)
    end

    self.parent:drawCircle(point.x, point.y, point.r, true, true)

    if self.isSelected then
        local brightenAmount = 0.2
        currentColor = {currentColor[1] + brightenAmount, currentColor[2] + brightenAmount, currentColor[3] + brightenAmount, currentColor[4], currentColor[5]}
        self.parent:drawCircle(point.x, point.y, point.r, false, true)
    end
end

--==============================================================
--== PolySelectLine ============================================
--==============================================================

local PolySelectLine = setmetatable({}, { __index = PolyLine })

function PolySelectLine:new(init)
    local init = init or {}
    local self = setmetatable(PolyLine:new(), { __index = self })

    self.selectedIndexes = {}

    self.activeColor =   init.activeColor    or { 0.3, 0.6, 1.0, 1.0, 0 }
    self.inactiveColor = init.inactiveColor  or { 1.0, 0.6, 0.3, 1.0, 0 }

    return self
end

function PolySelectLine:updateSelectedIndexes()
    self.selectedIndexes = {}
    local numberOfPoints = #self.points
    for i = 1, numberOfPoints do
        local point = self.points[i]
        if point.isSelected then
            self.selectedIndexes[#self.selectedIndexes + 1] = i
        end
    end
end
function PolySelectLine:insertPoint(point)
    local newPoint = Point:new(point)
    local newIndex = PolyLine.insertPoint(self, newPoint)
    self:updateSelectedIndexes()
    return newIndex
end
function PolySelectLine:moveSelectedPoints(xChange, yChange)
    self:moveSpecificPoints(self.selectedIndexes, xChange, yChange)
end
function PolySelectLine:moveSelectedPointsWithMouse()
    self:moveSpecificPointsWithMouse(self.selectedIndexes)
end
function PolySelectLine:getIndexOfPointClosestToPoint(x, y)
    local numberOfPoints = #self.points
    if numberOfPoints < 1 then return nil end

    local lowestDistance
    local lowestDistanceIndex = 1

    for i = 1, numberOfPoints do
        local point = self.points[i]
        local pointDistance = point:getDistanceTo(x, y)

        lowestDistance = lowestDistance or pointDistance

        if pointDistance < lowestDistance then
            lowestDistance = pointDistance
            lowestDistanceIndex = i
        end
    end

    return lowestDistanceIndex
end

function PolySelectLine:draw()
    PolyLine.draw(self)

    local numberOfPoints = #self.points
    for i = 1, numberOfPoints do
        self.points[i]:draw()
    end
end

return PolySelectLine