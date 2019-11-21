local reaper = reaper
local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local BoxSelect = require("GUI.BoxSelect")
local KeyEditor = require("Pitch Correction.KeyEditor")
local PitchCorrectedTake = require("Pitch Correction.PitchCorrectedTake")

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
    self.pitchCorrectionActiveColor = { 0.3, 0.6, 0.9, 1.0, 0 }
    self.pitchCorrectionInactiveColor = { 0.9, 0.3, 0.3, 1.0, 0 }
    self.take = PitchCorrectedTake:new{
        pointer = {
            get = function(self)
                local selectedItem = reaper.GetSelectedMediaItem(0, 0)
                if selectedItem then return reaper.GetActiveTake(selectedItem) end
            end
        }
    }
    self.previousTakePointer = self.take.pointer
    self.editPixelRange = 7
    self.fixErrorMode = false

    self.boxSelect = BoxSelect:new()
    self.childWidgets = { self.boxSelect }

    function self.pointIsInsideBoxSelect(box, point)
        return point.x >= box.x and point.x <= box.x + box.width
           and point.y >= box.y and point.y <= box.y + box.height
    end

    local points = self.take.corrections.points
    local time = 0
    local timeIncrement = self.take.sourceLength / 1000
    for i = 1, 1000 do
        self:insertPitchCorrectionPoint{
            time = time,
            pitch = 20.0 * math.random() + 50,
            isActive = math.random() > 0.5
        }
        time = time + timeIncrement
    end

    if self.take.pointer then self.take:loadPitchPointsFromTakeFile() end
    if object then for k, v in pairs(object) do self[k] = v end end
    return self
end

PitchEditor.keyPressFunctions = {
    ["Delete"] = function(self)
        if self.fixErrorMode then
        else
            self:deleteSelectedPitchCorrections()
        end
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
        else
            if self.GUI.shiftKey.isPressed then
                self:moveSelectedPitchCorrectionsByValues(0, -12.0)
            else
                self:moveSelectedPitchCorrectionsByValues(0, -1.0)
            end
        end
        self.take:correctAllPitchPoints()
    end,
    ["Up"] = function(self)
        if self.fixErrorMode then
            if self.GUI.shiftKey.isPressed then
                self:moveSelectedPitchPointsPitchesByValue(12.0)
            else
                self:moveSelectedPitchPointsPitchesByValue(1.0)
            end
        else
            if self.GUI.shiftKey.isPressed then
                self:moveSelectedPitchCorrectionsByValues(0, 12.0)
            else
                self:moveSelectedPitchCorrectionsByValues(0, 1.0)
            end
        end
        self.take:correctAllPitchPoints()
    end,
    ["s"] = function(self)
        if self.fixErrorMode then
        else
            self:insertPitchCorrectionPoint{
                time = self.mouseTime,
                pitch = self.snappedMousePitch,
                isSelected = false,
                isActive = false
            }
            self.take:correctAllPitchPoints()
        end
    end,
    ["d"] = function(self)
        if self.fixErrorMode then
        else
            local insertedIndex = self:insertPitchCorrectionPoint{
                time = self.mouseTime,
                pitch = self.snappedMousePitch,
                isSelected = false,
                isActive = false
            }
            local previousPoint = self.take.corrections.points[insertedIndex - 1]
            if previousPoint then previousPoint.isActive = true end
            self.take:correctAllPitchPoints()
        end
    end,
    ["S"] = function(self)
        if self.fixErrorMode then
        else
            self:insertPitchCorrectionPoint{
                time = self.mouseTime,
                pitch = self.mousePitch,
                isSelected = false,
                isActive = false
            }
            self.take:correctAllPitchPoints()
        end
    end,
    ["D"] = function(self)
        if self.fixErrorMode then
        else
            local insertedIndex = self:insertPitchCorrectionPoint{
                time = self.mouseTime,
                pitch = self.mousePitch,
                isSelected = false,
                isActive = false
            }
            local previousPoint = self.take.corrections.points[insertedIndex - 1]
            if previousPoint then previousPoint.isActive = true end
            self.take:correctAllPitchPoints()
        end
    end
}

function PitchEditor:updatePitchPointCoordinates()
    local take = self.take
    local points = take.pitches.points
    local timeToPixels = self.timeToPixels
    local pitchToPixels = self.pitchToPixels
    local reaperEnvelope_Evaluate = reaper.Envelope_Evaluate
    local envelope = take.pitchEnvelope
    local playRate = take.playRate
    for i = 1, #points do
        local point = points[i]
        point.time = take:getRealTime(point.sourceTime)
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
function PitchEditor:updatePitchCorrectionCoordinates()
    local take = self.take
    local points = take.corrections.points
    local timeToPixels = self.timeToPixels
    local pitchToPixels = self.pitchToPixels
    local reaperEnvelope_Evaluate = reaper.Envelope_Evaluate
    local envelope = take.pitchEnvelope
    local playRate = take.playRate
    for i = 1, #points do
        local point = points[i]
        point.time = take:getRealTime(point.sourceTime)
        local pointTime = point.time
        local pointPitch = point.pitch
        if pointTime then point.x = timeToPixels(self, pointTime) end
        if pointPitch then point.y = pitchToPixels(self, pointPitch) end
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
function PitchEditor:moveSelectedPitchPointsWithMouse()
    local timeChange = self.mouseTimeChange
    local pitchChange = 0
    if self.GUI.shiftKey.isPressed then
        pitchChange = self.mousePitchChange
    else
        pitchChange = self.snappedMousePitchChange
    end
    self:moveSelectedPitchPointsPitchesByValue(pitchChange)
end
function PitchEditor:moveSelectedPitchCorrectionsByValues(timeChange, pitchChange)
    local take = self.take
    local points = take.corrections.points
    for i = 1, #points do
        local point = points[i]
        if point.isSelected then
            point.pitch = point.pitch + pitchChange
            point.time = point.time + timeChange
            point.sourceTime = take:getSourceTime(point.time)
        end
    end
end
function PitchEditor:moveSelectedPitchCorrectionsWithMouse()
    local timeChange = self.mouseTimeChange
    local pitchChange = 0
    if self.GUI.shiftKey.isPressed then
        pitchChange = self.mousePitchChange
    else
        pitchChange = self.snappedMousePitchChange
    end
    self:moveSelectedPitchCorrectionsByValues(timeChange, pitchChange)
end
function PitchEditor:deleteSelectedPitchCorrections()
    local take = self.take
    local points = take.corrections.points
    arrayRemove(points, function(i, j)
        return points[i].isSelected
    end)
    take:correctAllPitchPoints()
end
function PitchEditor:setPitchCorrectionSelected(index, shouldSelect)
    local take = self.take
    local points = take.corrections.points
    points[index].isSelected = shouldSelect
end
function PitchEditor:unselectAllPitchCorrections()
    local take = self.take
    local points = take.corrections.points
    for i = 1, #points do
        points[i].isSelected = false
    end
end
function PitchEditor:toggleSelectedPitchCorrectionActivity()
    local take = self.take
    local points = take.corrections.points
    for i = 1, #points do
        local point = points[i]
        if point.isSelected then
            point.isActive = not point.isActive
        end
    end
end
function PitchEditor:insertPitchCorrectionPoint(point)
    local take = self.take
    local corrections = take.corrections.points
    local pointTime = point.time
    local pointPitch = point.pitch
    local newPoint = {
        time = pointTime,
        pitch = pointPitch,
        x = self:timeToPixels(pointTime),
        y = self:pitchToPixels(pointPitch),
        isSelected = point.isSelected,
        isActive = point.isActive
    }
    self.take:insertPitchCorrectionPoint(newPoint)
    take.corrections:sortPoints()
    for i = 1, #corrections do
        if corrections[i] == newPoint then return i end
    end
end
function PitchEditor:analyzePitch()
    self.take:prepareToAnalyzePitch()
end

function PitchEditor:update()
    KeyEditor.update(self)
    local GUI = self.GUI
    local rightMouseButton = GUI.rightMouseButton
    local leftMouseButton = GUI.leftMouseButton
    local shiftKey = GUI.shiftKey
    local altKey = GUI.altKey
    local take = self.take
    local takePointer = take.pointer

    if takePointer ~= self.previousTakePointer then
        take:loadPitchPointsFromTakeFile()
    end

    if self.fixErrorMode then
        self.mouseOverPitchPointIndex, self.mouseIsOverPitchPoint = getIndexOfPointOrSegmentClosestToPointWithinDistance(take.pitches.points, self.relativeMouseX, self.relativeMouseY, self.editPixelRange)
    else
        self.mouseOverPitchCorrectionIndex, self.mouseIsOverPitchCorrectionPoint = getIndexOfPointOrSegmentClosestToPointWithinDistance(take.corrections.points, self.relativeMouseX, self.relativeMouseY, self.editPixelRange)
    end

    if rightMouseButton:justPressedWidget(self) then
        self.boxSelect:startSelection(self.relativeMouseX, self.relativeMouseY)
    end
    if rightMouseButton:justDraggedWidget(self) then
        self.boxSelect:editSelection(self.relativeMouseX, self.relativeMouseY)
    end
    if rightMouseButton:justReleasedWidget(self) then
        local thingsToSelect = nil
        if self.fixErrorMode then
            thingsToSelect = self.take.pitches.points
        else
            thingsToSelect = self.take.corrections.points
        end
        self.boxSelect:makeSelection{
            thingsToSelect = thingsToSelect,
            thingIsInside = self.pointIsInsideBoxSelect,
            shouldAdd = GUI.shiftKey.isPressed,
            shouldInvert = GUI.controlKey.isPressed
        }
    end
    if leftMouseButton:justPressedWidget(self) then
        if self.mouseOverPitchCorrectionIndex then
            local mouseIsOverPoint = self.mouseIsOverPitchCorrectionPoint
            local editPointIndex = self.mouseOverPitchCorrectionIndex
            local editPoint = take.corrections.points[editPointIndex]
            local pointAfterEditPoint = take.corrections.points[editPointIndex + 1]
            local mouseIsOverActiveLine = not mouseIsOverPoint and editPoint.isActive

            if mouseIsOverPoint or mouseIsOverActiveLine then
                self.mousePitchCorrectionEditIndex = editPointIndex
            end
            if not editPoint.isSelected and not shiftKey.isPressed then
                self:unselectAllPitchCorrections()
            end
            if editPoint.isActive or mouseIsOverPoint then
                self:setPitchCorrectionSelected(editPointIndex, true)
            end
            if pointAfterEditPoint and mouseIsOverActiveLine then
                self:setPitchCorrectionSelected(editPointIndex + 1, true)
            end
            if altKey.isPressed then
                self.altKeyWasPressedWhenEditingPitchCorrection = true
                if mouseIsOverPoint or mouseIsOverActiveLine then
                    self:toggleSelectedPitchCorrectionActivity()
                    self.take:correctAllPitchPoints()
                end
            end
        end
        if self.mouseOverPitchPointIndex then
            self.mousePitchPointEditIndex = self.mouseOverPitchPointIndex
        end
    end
    if leftMouseButton:justDraggedWidget(self) then
        if self.mousePitchCorrectionEditIndex then
            if not self.altKeyWasPressedWhenEditingPitchCorrection then
                self:moveSelectedPitchCorrectionsWithMouse()
                take.corrections:sortPoints()
                self.take:correctAllPitchPoints()
            end
        end
        if self.mousePitchPointEditIndex then
            self:moveSelectedPitchPointsWithMouse()
        end
    end
    if leftMouseButton:justReleasedWidget(self) then
        self.mousePitchCorrectionEditIndex = nil
        self.mousePitchPointEditIndex = nil
        self.altKeyWasPressedWhenEditingPitchCorrection = nil
    end

    if takePointer ~= nil then
        take:analyzePitch()
        if take.isAnalyzingPitch then
            take.pitches:sortPoints()
        end
        self:updatePitchPointCoordinates()
    end
    take.corrections:sortPoints()
    self:updatePitchCorrectionCoordinates()

    self:queueRedraw()
    self.previousTakePointer = takePointer
end
function PitchEditor:drawPitchPoints()
    if self.take.pointer == nil then return end
    local abs = math.abs
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
function PitchEditor:drawPitchCorrections()
    if self.take.pointer == nil then return end
    local abs = math.abs
    local pointBrightness = 0.03
    local pointSize = 2
    local points = self.take.corrections.points
    local drawCircle = self.drawCircle
    local drawLine = self.drawLine
    local setColor = self.setColor
    local activeLineColor = self.pitchCorrectionActiveColor
    local activePointColor = { activeLineColor[1] + pointBrightness, activeLineColor[2] + pointBrightness, activeLineColor[3] + pointBrightness, activeLineColor[4], activeLineColor[5] }
    local inactivePointColor = self.pitchCorrectionInactiveColor
    local pitchToPixels = self.pitchToPixels
    local fixErrorMode = self.fixErrorMode
    local mouseOverIndex = self.mouseOverPitchCorrectionIndex
    local mouseIsOverPoint = self.mouseIsOverPitchCorrectionPoint
    local glowColor = { 1.0, 1.0, 1.0, 0.3, 1 }
    if not fixErrorMode then
        for i = 1, #points do
            local point = points[i]
            local nextPoint = points[i + 1]
            local shouldDrawLine = nextPoint and point.isActive
            local shouldGlowLine = point.isSelected or (mouseOverIndex == i and not mouseIsOverPoint)
            local shouldGlowPoint = point.isSelected or (mouseOverIndex == i and mouseIsOverPoint)

            -- Draw active lines.
            if shouldDrawLine then
                setColor(self, activeLineColor)
                drawLine(self, point.x, point.y, nextPoint.x, nextPoint.y, true)
                if shouldGlowLine then
                    setColor(self, glowColor)
                    drawLine(self, point.x, point.y, nextPoint.x, nextPoint.y, true)
                end
            end
            -- Draw the point colored based on whether or not it is active.
            if point.isActive then
                setColor(self, activePointColor)
            else
                setColor(self, inactivePointColor)
            end
            drawCircle(self, point.x, point.y, pointSize, true, true)
            if shouldGlowPoint then
                setColor(self, glowColor)
                drawCircle(self, point.x, point.y, pointSize, true, true)
            end
        end
    end
end
function PitchEditor:draw()
    KeyEditor.draw(self)
    self:drawPitchPoints()
    self:drawPitchCorrections()
end

return PitchEditor