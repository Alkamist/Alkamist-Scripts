local reaper = reaper
local math = math
local abs = math.abs
local min = math.min
local ceil = math.ceil
local table = table
local tableSort = table.sort
local type = type
local io = io

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
--local Json = require("dkjson")
local Proxy = require("Proxy")
local Widget = require("GUI.Widget")

local defaultModCorrection = 0.0
local defaultDriftCorrection = 1.0
local defaultDriftTime = 0.12

local function mainCommand(id)
    if type(id) == "string" then
        reaper.Main_OnCommand(reaper.NamedCommandLookup(id), 0)
    else
        reaper.Main_OnCommand(id, 0)
    end
end
local function getEELCommandID(name)
    local kbini = reaper.GetResourcePath() .. '/reaper-kb.ini'
    local file = io.open(kbini, 'r')

    local content = nil
    if file then
        content = file:read('a')
        file:close()
    end

    if content then
        local nameString = nil
        for line in content:gmatch('[^\r\n]+') do
            if line:match(name) then
                nameString = line:match('SCR %d+ %d+ ([%a%_%d]+)')
                break
            end
        end

        local commandID = nil
        if nameString then
            commandID = reaper.NamedCommandLookup('_' .. nameString)
        end

        if commandID and commandID ~= 0 then
            return commandID
        end
    end

    return nil
end
local function getSourceTime(take, time)
    if time == nil then return nil end
    local tempMarkerIndex = reaper.SetTakeStretchMarker(take, -1, time * reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE"))
    local _, _, sourceTime = reaper.GetTakeStretchMarker(take, tempMarkerIndex)
    reaper.DeleteTakeStretchMarkers(take, tempMarkerIndex)
    return sourceTime
end
local function getRealTime(take, sourceTime)
    if reaper.GetTakeNumStretchMarkers(take) < 1 then
        local startOffset = getSourceTime(take, 0.0)
        local playRate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
        return (sourceTime - startOffset) / playRate
    end

    local tolerance = 0.000001

    local guessTime = 0.0
    local guessSourceTime = getSourceTime(take, guessTime)
    local numberOfLoops = 0
    while true do
        local error = sourceTime - guessSourceTime
        if math.abs(error) < tolerance then break end

        local testGuessSourceTime = getSourceTime(take, guessTime + error)
        local seekRatio = math.abs( error / (testGuessSourceTime - guessSourceTime) )

        guessTime = guessTime + error * seekRatio
        guessSourceTime = getSourceTime(take, guessTime)

        numberOfLoops = numberOfLoops + 1
        if numberOfLoops > 100 then break end
    end

    return guessTime
end
local function getValuesFromStringLine(str)
    local values = {}
    local i = 1
    for value in str:gmatch("[%.%-%d]+") do
        values[i] = tonumber(value)
        i = i + 1
    end
    return values
end
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

local function lerp(x1, x2, ratio)
    return (1.0 - ratio) * x1 + ratio * x2
end
local function getLerpPitch(correction, nextCorrection, pitchPoint)
    local timeRatio = (pitchPoint.time - correction.time) / (nextCorrection.time - correction.time)
    return lerp(correction.pitch, nextCorrection.pitch, timeRatio)
end
local function getAveragePitch(correction, nextCorrection, index, group, timeRadius)
    local startingPoint = group[index]
    local pitchSum = startingPoint.pitch
    local numPoints = 1

    local currentPoint = startingPoint
    local smallestTimeToBoundary = math.min(math.abs(currentPoint.time - correction.time), math.abs(currentPoint.time - nextCorrection.time))
    local timeRadius = math.min(timeRadius, smallestTimeToBoundary)

    local i = index
    while true do
        i = i + 1
        currentPoint = group[i]
        if currentPoint == nil then break end

        if (currentPoint.time - startingPoint.time) >= timeRadius
        or currentPoint.time > nextCorrection.time then
            break
        end

        pitchSum = pitchSum + currentPoint.pitch
        numPoints = numPoints + 1
    end

    local i = index
    currentPoint = startingPoint
    while true do
        i = i - 1
        currentPoint = group[i]
        if currentPoint == nil then break end

        if (startingPoint.time - currentPoint.time) >= timeRadius
        or currentPoint.time < correction.time then
            break
        end

        pitchSum = pitchSum + currentPoint.pitch
        numPoints = numPoints + 1
    end

    return pitchSum / numPoints
end
local function getPitchCorrection(currentPitch, targetPitch, correctionStrength)
    return (targetPitch - currentPitch) * correctionStrength
end
local function getModCorrection(correction, nextCorrection, pitchPoint, currentCorrection)
    return getPitchCorrection(pitchPoint.pitch + currentCorrection,
                              getLerpPitch(correction, nextCorrection, pitchPoint),
                              correction.modCorrection)
end
local function getDriftCorrection(correction, nextCorrection, pitchIndex, pitchPoints)
    local pitchPoint = pitchPoints[pitchIndex]
    return getPitchCorrection(getAveragePitch(correction, nextCorrection, pitchIndex, pitchPoints, correction.driftTime * 0.5),
                              getLerpPitch(correction, nextCorrection, pitchPoint),
                              correction.driftCorrection)
end
local function clearEnvelopeUnderCorrection(correction, nextCorrection, envelope, playRate)
    reaper.DeleteEnvelopePointRange(envelope, correction.time * playRate, nextCorrection.time * playRate)
end
local function addZeroPointsToEnvelope(pitchIndex, pitchPoints, zeroPointThreshold, zeroPointSpacing, envelope, playRate)
    local point =         pitchPoints[pitchIndex]
    local previousPoint = pitchPoints[pitchIndex - 1]
    local nextPoint =     pitchPoints[pitchIndex + 1]

    local timeToPrevPoint = 0.0
    local timeToNextPoint = 0.0

    if previousPoint then
        timeToPrevPoint = point.time - previousPoint.time
    end

    if nextPoint then
        timeToNextPoint = nextPoint.time - point.time
    end

    if zeroPointThreshold then
        local scaledZeroPointThreshold = zeroPointThreshold / playRate

        if timeToPrevPoint >= scaledZeroPointThreshold or previousPoint == nil then
            local zeroPointTime = playRate * (point.time - zeroPointSpacing)
            reaper.DeleteEnvelopePointRange(envelope, zeroPointTime - zeroPointSpacing * 0.5, zeroPointTime + zeroPointSpacing * 0.5)
            reaper.InsertEnvelopePoint(envelope, zeroPointTime, 0, 0, 0, false, true)
        end

        if timeToNextPoint >= scaledZeroPointThreshold or nextPoint == nil then
            local zeroPointTime = playRate * (point.time + zeroPointSpacing)
            reaper.DeleteEnvelopePointRange(envelope, zeroPointTime - zeroPointSpacing * 0.5, zeroPointTime + zeroPointSpacing * 0.5)
            reaper.InsertEnvelopePoint(envelope, zeroPointTime, 0, 0, 0, false, true)
        end
    end
end
local function addEdgePointsToCorrection(correctionIndex, corrections, envelope, playRate)
    local correction =         corrections[correctionIndex]
    local previousCorrection = corrections[correctionIndex - 1]
    local nextCorrection =     corrections[correctionIndex + 1]
    local edgePointSpacing = 0.005

    if correction.isActive then
        if previousCorrection == nil or (previousCorrection and not previousCorrection.isActive) then
            reaper.InsertEnvelopePoint(envelope, (correction.time - edgePointSpacing) * playRate, 0.0, 0, 0, false, true)
        end
        if nextCorrection == nil then
            reaper.InsertEnvelopePoint(envelope, (correction.time + edgePointSpacing) * playRate, 0.0, 0, 0, false, true)
        end
    else
        reaper.InsertEnvelopePoint(envelope, (correction.time + edgePointSpacing) * playRate, 0.0, 0, 0, false, true)
    end
end
local function correctPitchPoints(correction, nextCorrection, pitchPoints, envelope, playRate)
    if nextCorrection then
        clearEnvelopeUnderCorrection(correction, nextCorrection, envelope, playRate)

        for i = 1, #pitchPoints do
            local pitchPoint = pitchPoints[i]
            if pitchPoint.time >= correction.time and pitchPoint.time <= nextCorrection.time then
                local driftCorrection = getDriftCorrection(correction, nextCorrection, i, pitchPoints)
                local modCorrection =   getModCorrection(correction, nextCorrection, pitchPoint, driftCorrection)
                reaper.InsertEnvelopePoint(envelope, pitchPoint.time * playRate, driftCorrection + modCorrection, 0, 0, false, true)
                addZeroPointsToEnvelope(i, pitchPoints, 0.2, 0.005, envelope, playRate)
            end
        end
    end
end

local function sortPointsByTime(points)
    tableSort(points, function(left, right)
        return left.time < right.time
    end)
end

local PitchCorrectedTake = {}
function PitchCorrectedTake:new(initialValues)
    local initialValues = initialValues or {}
    initialValues.shouldDrawDirectly = true
    local self = Widget:new(initialValues)

    self.pitchPoints = {}
    self.pitchCorrections = {}

    self.pitchPointColor = { 0.3, 0.7, 0.3, 1.0, 0 }

    self.item = { get = function(self) return reaper.GetSelectedMediaItem(0, 0) end }
    self.take = {
        get = function(self)
            local take
            local item = self.item
            if item then take = reaper.GetActiveTake(item) end
            if take and not reaper.TakeIsMIDI(take) then return take end
        end
    }
    self.name = {
        get = function(self)
            local take = self.take
            if take then return reaper.GetTakeName(take) end
        end
    }
    self.GUID = {
        get = function(self)
            local take = self.take
            if take then return reaper.BR_GetMediaItemTakeGUID(take) end
        end
    }
    self.source = {
        get = function(self)
            local take = self.take
            if take then return reaper.GetMediaItemTake_Source(take) end
        end
    }
    self.fileName = {
        get = function(self)
            local source = self.source
            if source then return reaper.GetMediaSourceFileName(source, ""):match("[^/\\]+$") end
        end
    }
    self.sampleRate = {
        get = function(self)
            local source = self.source
            if source then return reaper.GetMediaSourceSampleRate(source) end
        end
    }
    self.playRate = {
        get = function(self)
            local take = self.take
            if take then return reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE") end
        end
    }
    self.startOffset = {
        get = function(self)
            local take = self.take
            if take then return getSourceTime(take, 0.0) end
        end
    }
    self.track = {
        get = function(self)
            local item = self.item
            if item then return reaper.GetMediaItem_Track(item) end
        end
    }
    self.length = {
        get = function(self)
            local item = self.item
            if item then return reaper.GetMediaItemInfo_Value(item, "D_LENGTH") end
        end
    }
    self.leftTime = {
        get = function(self)
            local item = self.item
            if item then return reaper.GetMediaItemInfo_Value(item, "D_POSITION") end
        end
    }
    self.rightTime = {
        get = function(self)
            local leftTime = self.leftTime
            local rightTime = self.length
            if leftTime and rightTime then return leftTime + length end
        end
    }
    self.sourceLength = {
        get = function(self)
            local source = self.source
            if source then
                local _, _, sourceLength = reaper.PCM_Source_GetSectionInfo(source)
                return sourceLength
            end
        end
    }
    self.analyzerID = {
        get = function(self)
            local analyzerID = getEELCommandID("WritePitchPointsToExtState")
            if not analyzerID then
                reaper.MB("WritePitchPointsToExtState.eel not found!", "Error!", 0)
                return
            end
            return analyzerID
        end
    }
    self.envelope = { get = function(self) return self:activateEnvelope() end }
    self.pitchDetectionSettings = {
        windowStep = 0.04,
        windowOverlap = 2.0,
        minimumFrequency = 80,
        maximumFrequency = 1000,
        threshold = 0.2,
        minimumRMSdB = -60.0
    }
    self.analyzeFullSource = false
    self.numberOfPointsToAnalyzePerLoop = 10
    self.analysisTimeWindow = {
        get = function(self)
            local settings = self.pitchDetectionSettings
            local timeWindow = self.numberOfPointsToAnalyzePerLoop * settings.windowStep / settings.windowOverlap
            return min(timeWindow, self.analysisEndTime - self.analysisStartTime)
        end
    }
    self.analysisStartTime = 0
    self.analysisEndTime = {
        get = function(self)
            if self.analyzeFullSource then
                return self.sourceLength
            end
            return getSourceTime(self.take, self.length)
        end
    }
    self.analysisLength = { get = function(self) return self.analysisEndTime - self.analysisStartTime end }
    self.numberOfAnalysisLoops = {
        get = function(self)
            local timeWindow = self.analysisTimeWindow
            if timeWindow == 0 then return 0 end
            if self.analyzeFullSource then
                return ceil(self.sourceLength / timeWindow)
            end
            return ceil(self.analysisLength / timeWindow)
        end
    }
    self.isAnalyzingPitch = false
    self.newPointsHaveBeenInitialized = true

    function self:activateEnvelope()
        local take = self.take
        local pitchEnvelope = reaper.GetTakeEnvelopeByName(take, "Pitch")
        if not pitchEnvelope or not reaper.ValidatePtr2(0, pitchEnvelope, "TrackEnvelope*") then
            mainCommand("_S&M_TAKEENV10") -- Show and unbypass take pitch envelope
            pitchEnvelope = reaper.GetTakeEnvelopeByName(take, "Pitch")
            --mainCommand("_S&M_TAKEENVSHOW8") -- Hide take pitch envelope
        end
        return pitchEnvelope
    end
    function self:clearEnvelope()
        local envelope = self.envelope
        reaper.DeleteEnvelopePointRange(envelope, -self.startOffset, self.sourceLength * self.playRate)
        reaper.Envelope_SortPoints(envelope)
        reaper.UpdateArrange()
    end
    function self:removeDuplicatePitchPoints(tolerance)
        local tolerance = tolerance or 0.0001
        local newPoints = {}
        local points = self.pitchPoints
        for i = 1, #points do
            local point = points[i]
            local pointIsDuplicate = false
            for j = 1, #newPoints do
                if abs(point.time - newPoints[j].time) < tolerance then
                    pointIsDuplicate = true
                end
            end
            if not pointIsDuplicate then
                newPoints[#newPoints + 1] = point
            end
        end
        self.pitchPoints = newPoints
    end
    function self:getPitchPointsFromExtState()
        local pointString = reaper.GetExtState("AlkamistPitchCorrection", "PITCHPOINTS")
        local points = self.pitchPoints
        for line in pointString:gmatch("([^\r\n]+)") do
            local values = getValuesFromStringLine(line)
            local pointTime = values[1]
            local point = {
                time =       getRealTime(self.take, pointTime),
                sourceTime = pointTime,
                pitch =      values[2],
                --rms =        values[3]
            }
            points[#points + 1] = point
        end
    end
    function self:clearPitchPointsWithinTimeRange(leftTime, rightTime)
        local points = self.pitchPoints
        arrayRemove(points, function(i, j)
            return points[i].time >= leftTime and points[i].time <= rightTime
        end)
    end
    function self:prepareToAnalyzePitch(analyzeFullSource)
        if self.take == nil then return end

        local settings = self.pitchDetectionSettings
        reaper.SetExtState("AlkamistPitchCorrection", "TAKEGUID", self.GUID, false)
        reaper.SetExtState("AlkamistPitchCorrection", "WINDOWSTEP", settings.windowStep, false)
        reaper.SetExtState("AlkamistPitchCorrection", "WINDOWOVERLAP", settings.windowOverlap, false)
        reaper.SetExtState("AlkamistPitchCorrection", "MINIMUMFREQUENCY", settings.minimumFrequency, false)
        reaper.SetExtState("AlkamistPitchCorrection", "MAXIMUMFREQUENCY", settings.maximumFrequency, false)
        reaper.SetExtState("AlkamistPitchCorrection", "THRESHOLD", settings.threshold, false)
        reaper.SetExtState("AlkamistPitchCorrection", "MINIMUMRMSDB", settings.minimumRMSdB, false)

        self.analyzeFullSource = analyzeFullSource
        self.analysisLoopsCompleted = 0
        self.isAnalyzingPitch = true
        self.newPointsHaveBeenInitialized = false
        if self.analyzeFullSource then
            self.analysisStartTime = 0.0
        else
            self.analysisStartTime = self.startOffset
        end

        self:clearPitchPointsWithinTimeRange(0.0, self.length)
        self:clearEnvelope()
    end
    function self:analyzePitch()
        if self.isAnalyzingPitch then
            local analysisTimeWindow = self.analysisTimeWindow
            reaper.SetExtState("AlkamistPitchCorrection", "STARTTIME",  self.analysisStartTime,  false)
            reaper.SetExtState("AlkamistPitchCorrection", "TIMEWINDOW", analysisTimeWindow, false)

            mainCommand(self.analyzerID)
            self:getPitchPointsFromExtState()

            self.analysisStartTime = self.analysisStartTime + analysisTimeWindow
            self.isAnalyzingPitch = self.numberOfAnalysisLoops > 0
        else
            if not self.newPointsHaveBeenInitialized then
                self:removeDuplicatePitchPoints()
                --self:savePitchPoints()
                --self:correctAllPitchPoints()
                self.newPointsHaveBeenInitialized = true
            end
        end
    end

    function self:correctAllPitchPoints()
        self:clearEnvelope()
        local corrections = self.pitchCorrections
        local pitchPoints = self.pitchPoints
        local envelope = self.envelope
        local playRate = self.playRate
        for i = 1, #corrections do
            local correction = corrections[i]
            local nextCorrection = corrections[i + 1]

            addEdgePointsToCorrection(i, corrections, envelope, playRate)
            if correction.isActive and nextCorrection then
                correctPitchPoints(correction, nextCorrection, pitchPoints, envelope, playRate)
            end
        end
        reaper.Envelope_SortPoints(envelope)
        reaper.UpdateArrange()
    end
    function self:insertPitchCorrectionPoint(point)
        point.sourceTime = getSourceTime(self.take, point.time)
        point.driftTime = point.driftTime or defaultDriftTime
        point.driftCorrection = point.driftCorrection or defaultDriftCorrection
        point.modCorrection = point.modCorrection or defaultModCorrection
        self.pitchCorrections[#self.pitchCorrections + 1] = point
        sortPointsByTime(self.pitchCorrections)
    end

    function self:drawPitchPoints()
        local points = self.pitchPoints
        local pitchPointColor = self.pitchPointColor
        local size = 3
        for i = 1, #points do
            local point = points[i]
            local nextPoint = points[i + 1]
            if nextPoint then
                if nextPoint.time - point.time < 0.1 then
                    self:setColor(pitchPointColor)
                    self:drawLine(point.x, point.y, nextPoint.x, nextPoint.y, true)
                end
            end
            self:setColor(pitchPointColor)
            self:drawRectangle(point.x - 1, point.y - 1, size, size, true)
        end
    end
    function self:draw()
        self:drawPitchPoints()
    end

    return Proxy:new(self, initialValues)
end

return PitchCorrectedTake