local reaper = reaper
local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local BoxSelect = require("GUI.BoxSelect")
local KeyEditor = require("Pitch Correction.KeyEditor")
local TakeWithPitchPoints = require("Pitch Correction.TakeWithPitchPoints")

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
    local self = KeyEditor:new(self)

    self.timeLength = {
        get = function()
            local takeLength = self.take.length
            if takeLength then return takeLength end
            return 0.0
        end
    }
    self.startTime = {
        get = function()
            local startTime = self.take.leftTime
            if startTime then return startTime end
            return 0.0
        end
    }

    self.pitchLineColor = { 0.07, 0.27, 0.07, 1.0, 0 }
    self.correctedPitchLineColor = { 0.24, 0.64, 0.24, 1.0, 0 }
    self.take = TakeWithPitchPoints:new{
        pointer = {
            get = function(self)
                local selectedItem = reaper.GetSelectedMediaItem(0, 0)
                if selectedItem then return reaper.GetActiveTake(selectedItem) end
            end
        }
    }
    self.previousTakePointer = self.take.pointer
    self.mouseOverPitchPointIndex = nil
    self.mouseIsOverPitchPoint = nil
    self.editPixelRange = 7
    self.fixErrorMode = false

    self.boxSelect = BoxSelect:new()
    self.childWidgets = { self.boxSelect }

    if self.take.pointer then self.take:loadPitchPointsFromTakeFile() end
    if object then for k, v in pairs(object) do self[k] = v end end
    return self
end

PitchEditor.keyPressFunctions = {
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
            if self.GUI.shiftKey.isPressed then
                self:moveSelectedPitchPointsPitchesByValue(-12.0)
            else
                self:moveSelectedPitchPointsPitchesByValue(-1.0)
            end
        end
    end,
    ["Up"] = function(self)
        if self.fixErrorMode then
            if self.GUI.shiftKey.isPressed then
                self:moveSelectedPitchPointsPitchesByValue(12.0)
            else
                self:moveSelectedPitchPointsPitchesByValue(1.0)
            end
        end
    end
}

function PitchEditor:updatePointCoordinates(points)
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
function PitchEditor:moveSelectedPitchPointsPitchesByValue(value)
    local points = self.take.pitches.points
    for i = 1, #points do
        local point = points[i]
        if point.isSelected then
            point.pitch = point.pitch + value
        end
    end
end

function PitchEditor:analyzePitch()
    self.take:prepareToAnalyzePitch()
end
function PitchEditor:update()
    KeyEditor.update(self)

    local GUI = self.GUI
    local rightMouseButton = GUI.rightMouseButton
    if rightMouseButton:justPressedWidget(self) then
        self.boxSelect:startSelection(self.relativeMouseX, self.relativeMouseY)
    end
    if rightMouseButton:justDraggedWidget(self) then
        self.boxSelect:editSelection(self.relativeMouseX, self.relativeMouseY)
    end
    if rightMouseButton:justReleasedWidget(self) then
        local thingsToSelect = nil
        if self.fixErrorMode then thingsToSelect = self.take.pitches.points end
        self.boxSelect:makeSelection{
            thingsToSelect = thingsToSelect,
            shouldAdd = GUI.shiftKey.isPressed,
            shouldInvert = GUI.controlKey.isPressed
        }
    end

    local take = self.take
    local takePointer = take.pointer

    if takePointer ~= self.previousTakePointer then
        take:loadPitchPointsFromTakeFile()
    end

    if self.fixErrorMode then
        self.mouseOverPitchPointIndex, self.mouseIsOverPitchPoint = getIndexOfPointOrSegmentClosestToPointWithinDistance(take.pitches.points, self.relativeMouseX, self.relativeMouseY, self.editPixelRange)
    end

    if takePointer ~= nil then
        take:analyzePitch()
        take.pitches:sortPoints()
        self:updatePointCoordinates(take.pitches.points)
    end

    self:queueRedraw()
    self.previousTakePointer = takePointer
end
function PitchEditor:drawPitchPoints()
    if self.take.pointer == nil then return end
    local pointBrightness = 0.03
    local pointSize = 3
    local halfPointSize = math.floor(pointSize * 0.5)
    local points = self.take.pitches.points
    local drawRectangle = self.drawRectangle
    local drawLine = self.drawLine
    local setColor = self.setColor
    local lineColor = self.pitchLineColor
    local pointColor = { lineColor[1] + pointBrightness, lineColor[2] + pointBrightness, lineColor[3] + pointBrightness, lineColor[4], lineColor[5] }
    local correctedLineColor = self.correctedPitchLineColor
    local correctedPointColor = { correctedLineColor[1] + pointBrightness, correctedLineColor[2] + pointBrightness, correctedLineColor[3] + pointBrightness, correctedLineColor[4], correctedLineColor[5] }
    local pitchToPixels = self.pitchToPixels
    local abs = math.abs
    local fixErrorMode = self.fixErrorMode
    local mouseOverIndex = self.mouseOverPitchPointIndex
    local mouseIsOverPoint = self.mouseIsOverPitchPoint
    local glowColor = { 1.0, 1.0, 1.0, 0.3, 1 }
    for i = 1, #points do
        local point = points[i]
        local nextPoint = points[i + 1]
        local shouldDrawLine = nextPoint and abs(nextPoint.time - point.time) < 0.1

        if fixErrorMode then
            -- Draw the normal line in the corrected color
            -- with additional mouse over and selection glow.
            local shouldGlowLine = point.isSelected or (mouseOverIndex == i and not mouseIsOverPoint)
            local shouldGlowPoint = point.isSelected or (mouseOverIndex == i and mouseIsOverPoint)
            if shouldDrawLine then
                setColor(self, correctedLineColor)
                drawLine(self, point.x, point.y, nextPoint.x, nextPoint.y, true)
                if shouldGlowLine then
                    setColor(self, glowColor)
                    drawLine(self, point.x, point.y, nextPoint.x, nextPoint.y, true)
                end
            end
            setColor(self, correctedPointColor)
            drawRectangle(self, point.x - halfPointSize, point.y - halfPointSize, pointSize, pointSize, true)
            if shouldGlowPoint then
                setColor(self, glowColor)
                drawRectangle(self, point.x - halfPointSize, point.y - halfPointSize, pointSize, pointSize, true)
            end
        else
            -- Draw the normal line and point.
            if shouldDrawLine then
                setColor(self, lineColor)
                drawLine(self, point.x, point.y, nextPoint.x, nextPoint.y, true)
            end
            setColor(self, pointColor)
            drawRectangle(self, point.x - halfPointSize, point.y - halfPointSize, pointSize, pointSize, true)

            -- Draw the corrected line and point.
            if shouldDrawLine then
                setColor(self, correctedLineColor)
                drawLine(self, point.x, point.correctedY, nextPoint.x, nextPoint.correctedY, true)
            end
            setColor(self, correctedPointColor)
            drawRectangle(self, point.x - halfPointSize, point.correctedY - halfPointSize, pointSize, pointSize, true)
        end
    end
end
function PitchEditor:draw()
    KeyEditor.draw(self)
    self:drawPitchPoints()
end

return PitchEditor