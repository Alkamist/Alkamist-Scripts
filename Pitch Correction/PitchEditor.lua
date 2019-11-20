local reaper = reaper
local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Widget = require("GUI.Widget")
local Button = require("GUI.Button")
local KeyEditor = require("Pitch Correction.KeyEditor")

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

local PitchEditor = {}
function PitchEditor:new(object)
    local self = Widget:new(self)

    self.fixErrorMode = { get = function(self) return self.fixErrorButton.isPressed end }

    self.fixErrorButton = Button:new{
        x = 79,
        y = 0,
        width = 80,
        height = 25,
        label = "Fix Errors",
        toggleOnClick = true
    }
    self.analyzeButton = Button:new{
        x = 0,
        y = 0,
        width = 80,
        height = 25,
        label = "Analyze Pitch",
        color = { 0.5, 0.2, 0.1, 1.0, 0 }
    }
    self.keyEditor = KeyEditor:new{
        x = 0,
        y = 25,
        width = object.width,
        height = object.height
    }
    self.childWidgets = { self.keyEditor, self.analyzeButton, self.fixErrorButton }

    if object then for k, v in pairs(object) do self[k] = v end end
    return self
end

--[[function self:updatePointCoordinates(points)
    local timeToPixels = self.timeToPixels
    local pitchToPixels = self.pitchToPixels
    local reaperEnvelope_Evaluate = reaper.Envelope_Evaluate
    local envelope = self.take.pitchEnvelope
    local playRate = self.take.playRate
    for i = 1, #points do
        local point = points[i]
        point.time = self.take:getRealTime(point.sourceTime)
        local pointTime = point.time
        local pointPitch = point.pitch
        if pointTime then
            point.x = timeToPixels(self, pointTime)
            if pointPitch then
                point.y = pitchToPixels(self, pointPitch)
                local _, envelopeValue = reaperEnvelope_Evaluate(envelope, pointTime * playRate, 44100, 0)
                point.correctedY = pitchToPixels(self, pointPitch + envelopeValue)
            end
        end
    end
end
function self:moveSelectedPitchPointsPitchesBy(value)
    local points = self.take.pitchAnalyzer.points
    for i = 1, #points do
        local point = points[i]
        if point.isSelected then
            point.pitch = point.pitch + value
        end
    end
end]]--

--[[self.keyPressFunctions = {
    ["Delete"] = function(self)
        msg("delete")
    end,
    ["e"] = function(self)
        reaper.SetEditCurPos(self.startTime + self.mouseTime, false, true)
        reaper.UpdateArrange()
        reaper.Main_OnCommandEx(1007, 0, 0)
    end,
    ["Down"] = function(self)
        if self.fixErrorMode then
            if self.GUI.keyboard.shiftKey.isPressed then
                self:moveSelectedPitchPointsPitchesBy(-12.0)
            else
                self:moveSelectedPitchPointsPitchesBy(-1.0)
            end
        end
    end,
    ["Up"] = function(self)
        if self.fixErrorMode then
            if self.GUI.keyboard.shiftKey.isPressed then
                self:moveSelectedPitchPointsPitchesBy(12.0)
            else
                self:moveSelectedPitchPointsPitchesBy(1.0)
            end
        end
    end
}]]--

--[[function PitchEditor:update()
    --if self.fixErrorMode then
    --    self.mouseOverPitchPointIndex, self.mouseIsOverPitchPoint = getIndexOfPointOrSegmentClosestToPointWithinDistance(pitchAnalyzer.points, self.relativeMouseX, self.relativeMouseY, self.editPixelRange)
    --end

    --if takePointer ~= nil then
    --    if self.analyzeButton.justPressed then pitchAnalyzer:prepareToAnalyzePitch() end
    --    pitchAnalyzer:analyzePitch()
    --    pitchAnalyzer:sortPoints()
    --    self:updatePointCoordinates(pitchAnalyzer.points)
    --end

    --self:queueRedraw()
end]]--
--[[function self:drawPitchPoints()
    if self.take.pointer == nil then return end
    local points = self.take.pitchAnalyzer.points
    local drawRectangle = self.drawRectangle
    local drawLine = self.drawLine
    local setColor = self.setColor
    local pointColor = self.pitchPointColor
    local lineColor = self.pitchLineColor
    local correctedLineColor = self.correctedPitchLineColor
    local mouseOverLineColor = self.pitchLineMouseOverColor
    local correctedPointColor = self.correctedPitchPointColor
    local mouseOverPointColor = self.pitchPointMouseOverColor
    local pitchToPixels = self.pitchToPixels
    local abs = math.abs
    local fixErrorMode = self.fixErrorMode
    local mouseOverIndex = self.mouseOverPitchPointIndex
    local mouseIsOverPoint = self.mouseIsOverPitchPoint
    local selectedColor = { 1.0, 1.0, 1.0, 0.3, 1 }
    for i = 1, #points do
        local point = points[i]
        local nextPoint = points[i + 1]
        local shouldDrawLine = nextPoint and abs(nextPoint.time - point.time) < 0.1

        if fixErrorMode then
            if shouldDrawLine then
                if mouseOverIndex == i and not mouseIsOverPoint then
                    setColor(self, mouseOverLineColor)
                else
                    setColor(self, correctedLineColor)
                end
                drawLine(self, point.x, point.y, nextPoint.x, nextPoint.y, true)
            end
            if mouseOverIndex == i and mouseIsOverPoint then
                setColor(self, mouseOverPointColor)
            else
                setColor(self, correctedPointColor)
            end
            drawRectangle(self, point.x - 1, point.y - 1, 3, 3, true)
            if point.isSelected then
                setColor(self, selectedColor)
                drawRectangle(self, point.x - 1, point.y - 1, 3, 3, true)
            end
        else
            if shouldDrawLine then
                setColor(self, lineColor)
                drawLine(self, point.x, point.y, nextPoint.x, nextPoint.y, true)
            end
            setColor(self, pointColor)
            drawRectangle(self, point.x - 1, point.y - 1, 3, 3, true)

            if shouldDrawLine then
                setColor(self, correctedLineColor)
                drawLine(self, point.x, point.correctedY, nextPoint.x, nextPoint.correctedY, true)
            end
            setColor(self, correctedPointColor)
            drawRectangle(self, point.x - 1, point.correctedY - 1, 3, 3, true)
        end
    end
end]]--
--[[function PitchEditor:draw()
end]]--

return PitchEditor