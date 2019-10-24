local PolyLine = {}

function PolyLine:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.points = {}

    if init.isHorizontal ~= nil then
        self.isHorizontal = init.isHorizontal
    else
        self.isHorizontal = true
    end

    self.activeColor =   init.activeColor    or { 0.3, 0.6, 1.0, 1.0, 0 }
    self.inactiveColor = init.inactiveColor  or { 1.0, 0.6, 0.3, 1.0, 0 }

    return self
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

function PolyLine:updateSelectedIndexes()
    self.selectedNodeIndexes = {}
    local numberOfNodes = #self.nodes
    for i = 1, numberOfNodes do
        local node = self.nodes[i]
        if node.isSelected then
            self.selectedNodeIndexes[#self.selectedNodeIndexes + 1] = i
        end
    end
end
function PolyLine:insertPoint(point)
    local newIndex

    if self.isHorizontal then
        newIndex = insertThingIntoGroup(self.points, point, function(pointInLoop, newPoint)
            return pointInLoop.x >= newPoint.x
        end)
    else
        newIndex = insertThingIntoGroup(self.points, point, function(pointInLoop, newPoint)
            return pointInLoop.y >= newPoint.y
        end)
    end

    self:updateSelectedIndexes()
end
function PolyLine:sortPoints()
    if self.isHorizontal then
        table.sort(self.points, function(left, right)
            return left.x < right.x
        end)
    else
        table.sort(self.points, function(left, right)
            return left.y < right.y
        end)
    end
end



function PolyLine:moveSelectedNodesWithMouse()
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
function PolyLine:moveSelectedNodesByCoordinateChange(xChange, yChange)
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
function PolyLine:getIndexOfNodeClosestToMouse()
    local numberOfNodes = #self.nodes
    if numberOfNodes < 1 then return nil end

    local node
    local nextNode
    local lowestDistance
    local isLine = false

    for i = 1, numberOfNodes do
        node = self.nodes[i]
        if i < numberOfNodes then nextNode = self.nodes[i + 1] end

        local nodeDistance = distanceBetweenTwoPoints(node.x, node.y, self.relativeMouseX, self.relativeMouseY)
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

function PolyLine:onDraw()
    local numberOfPoints = #self.points
    for i = 1, numberOfPoints do
        local point =     self.points[i]
        local nextPoint = self.points[i + 1]

        if point.isActive then
            self:setColor(self.activeColor)
        else
            self:setColor(self.inactiveColor)
        end

        local normalColor = self.currentColor
        local brightenedColor = {self.currentColor[1] + 0.2, self.currentColor[2] + 0.2, self.currentColor[3] + 0.2, self.currentColor[4]}

        if i == self.mouseOverpointIndex and not self.mouseIsOverLine then
            self:setColor(brightenedColor)
        end

        self:drawCircle(point.x, point.y, self.pointCirclePixelRadius, point.isSelected, true)

        if i == self.mouseOverpointIndex and self.mouseIsOverLine then
            self:setColor(brightenedColor)
        else
            self:setColor(normalColor)
        end

        if point.isActive and nextPoint then
            self:drawLine(point.x, point.y, nextPoint.x, nextPoint.y, true)
        end
    end
end

return PolyLine