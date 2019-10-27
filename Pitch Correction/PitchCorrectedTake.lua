local reaper = reaper

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local PolyLine = require("GFX.PolyLine")

--==============================================================
--== Helpful Functions =========================================
--==============================================================

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
local function getSourcePosition(take, time)
    if time == nil then return nil end
    local tempMarkerIndex = reaper.SetTakeStretchMarker(take, -1, time * reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE"))
    local _, realTime, sourceTime = reaper.GetTakeStretchMarker(take, tempMarkerIndex)
    reaper.DeleteTakeStretchMarkers(take, tempMarkerIndex)
    return sourceTime
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

--==============================================================
--== Pitch Correction Functions ================================
--==============================================================

local function lerp(x1, x2, ratio)
    return (1.0 - ratio) * x1 + ratio * x2
end
local function getLerpPitch(correction, nextCorrection, pitchPoint)
    local timeRatio = (pitchPoint.time - correction.time) / (nextCorrection.time - correction.time)
    return lerp(correction.pitch, nextCorrection.pitch, timeRatio)
end
local function getAveragePitch(index, group, timeRadius)
    local startingPoint = group[index]
    local pitchSum = startingPoint.pitch
    local numPoints = 1

    local i = index
    local currentPoint = startingPoint
    while true do
        i = i + 1
        currentPoint = group[i]
        if currentPoint == nil then break end

        if (currentPoint.time - startingPoint.time) >= timeRadius then
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

        if (startingPoint.time - currentPoint.time) >= timeRadius then
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
    return getPitchCorrection(getAveragePitch(pitchIndex, pitchPoints, correction.driftTime * 0.5),
                              getLerpPitch(correction, nextCorrection, pitchPoint),
                              correction.driftCorrection)
end
local function addPitchCorrectionToEnvelope(correction, time, envelope, playrate)
    reaper.InsertEnvelopePoint(envelope, time * playrate, correction, 0, 0, false, true)
end
local function clearEnvelopeUnderCorrection(correction, nextCorrection, envelope, playrate)
    reaper.DeleteEnvelopePointRange(envelope, correction.time * playrate, nextCorrection.time * playrate)
end
local function addZeroPointsToEnvelope(pitchIndex, pitchPoints, zeroPointThreshold, zeroPointSpacing, envelope, playrate)
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
        local scaledZeroPointThreshold = zeroPointThreshold / playrate

        if timeToPrevPoint >= scaledZeroPointThreshold or previousPoint == nil then
            local zeroPointTime = playrate * (point.time - zeroPointSpacing)
            reaper.DeleteEnvelopePointRange(envelope, zeroPointTime - zeroPointSpacing * 0.5, zeroPointTime + zeroPointSpacing * 0.5)
            reaper.InsertEnvelopePoint(envelope, zeroPointTime, 0, 0, 0, false, true)
        end

        if timeToNextPoint >= scaledZeroPointThreshold or nextPoint == nil then
            local zeroPointTime = playrate * (point.time + zeroPointSpacing)
            reaper.DeleteEnvelopePointRange(envelope, zeroPointTime - zeroPointSpacing * 0.5, zeroPointTime + zeroPointSpacing * 0.5)
            reaper.InsertEnvelopePoint(envelope, zeroPointTime, 0, 0, 0, false, true)
        end
    end
end
local function addEdgePointsToCorrection(correctionIndex, corrections, envelope, playrate)
    local correction =         corrections[correctionIndex]
    local previousCorrection = corrections[correctionIndex - 1]
    local nextCorrection =     corrections[correctionIndex + 1]
    local edgePointSpacing = 0.005

    if correction.isActive then
        if previousCorrection == nil or (previousCorrection and not previousCorrection.isActive) then
            reaper.InsertEnvelopePoint(envelope, (correction.time - edgePointSpacing) * playrate, 0.0, 0, 0, false, true)
        end
        if nextCorrection == nil then
            reaper.InsertEnvelopePoint(envelope, (correction.time + edgePointSpacing) * playrate, 0.0, 0, 0, false, true)
        end
    else
        reaper.InsertEnvelopePoint(envelope, (correction.time + edgePointSpacing) * playrate, 0.0, 0, 0, false, true)
    end
end
local function correctPitchPoints(correction, nextCorrection, pitchPoints, envelope, playrate)
    if nextCorrection then
        clearEnvelopeUnderCorrection(correction, nextCorrection, envelope, playrate)

        for i = 1, #pitchPoints do
            local pitchPoint = pitchPoints[i]
            if pitchPoint.time >= correction.time and pitchPoint.time <= nextCorrection.time then
                local driftCorrection = getDriftCorrection(correction, nextCorrection, i, pitchPoints)
                local modCorrection =   getModCorrection(correction, nextCorrection, pitchPoint, driftCorrection)
                addPitchCorrectionToEnvelope(driftCorrection + modCorrection, pitchPoint.time, envelope, playrate)
                addZeroPointsToEnvelope(i, pitchPoints, 0.04, 0.005, envelope, playrate)
            end
        end
    end
end

--==============================================================
--== Pitch Corrected Take ======================================
--==============================================================

local PitchCorrectedTake = {}

function PitchCorrectedTake:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.parent =      init.parent
    self.pitches =     PolyLine:new()
    self.corrections = PolyLine:new()
    self:set(init.take)

    return self
end

function PitchCorrectedTake:clear()
    self.pointer =            nil
    self.takeName =           nil
    self.takeGUID =           nil
    self.takeSource =         nil
    self.takeFileName =       nil
    self.playrate =           nil
    self.startOffset =        nil
    self.envelope =           nil
    self.takeSourceLength =   nil
    self.item =               nil
    self.track =              nil
    self.length =             nil
    self.leftTime =           nil
    self.rightTime =          nil
    self.pitches.points =     {}
    self.corrections.points = {}
end
function PitchCorrectedTake:activateEnvelope()
    local pitchEnvelope = reaper.GetTakeEnvelopeByName(self.pointer, "Pitch")
    if not pitchEnvelope or not reaper.ValidatePtr2(0, pitchEnvelope, "TrackEnvelope*") then
        mainCommand("_S&M_TAKEENV10") -- Show and unbypass take pitch envelope
        pitchEnvelope = reaper.GetTakeEnvelopeByName(self.pointer, "Pitch")
    end
    --mainCommand("_S&M_TAKEENVSHOW8") -- Hide take pitch envelope
    return pitchEnvelope
end
function PitchCorrectedTake:set(take)
    if take == nil then
        self:clear()
        return
    end
    if reaper.TakeIsMIDI(take) then
        self:clear()
        return
    end
    if take == self.pointer then
        return
    end

    self.pointer =      take
    self.name =         reaper.GetTakeName(self.pointer)
    self.GUID =         reaper.BR_GetMediaItemTakeGUID(self.pointer)
    self.source =       reaper.GetMediaItemTake_Source(self.pointer)
    self.fileName =     reaper.GetMediaSourceFileName(self.source, ""):match("[^/\\]+$")
    self.sampleRate =   reaper.GetMediaSourceSampleRate(self.source)
    self.playrate =     reaper.GetMediaItemTakeInfo_Value(self.pointer, "D_PLAYRATE")
    self.startOffset =  getSourcePosition(self.pointer, 0.0)
    self.envelope =     self:activateEnvelope()
    _, _, self.takeSourceLength = reaper.PCM_Source_GetSectionInfo(self.source)

    self.item =         reaper.GetMediaItemTake_Item(self.pointer)
    self.track =        reaper.GetMediaItem_Track(self.item)
    self.length =       reaper.GetMediaItemInfo_Value(self.item, "D_LENGTH")
    self.leftTime =     reaper.GetMediaItemInfo_Value(self.item, "D_POSITION")
    self.rightTime =    self.leftTime + self.length

    self.pitches.points     = {}
    self.corrections.points = {}

    self:clearEnvelope()
    --self:loadSavedPoints()
    --self.minTimePerPoint = self:getMinTimePerPoint()
    --self.minSourceTimePerPoint = self:getMinSourceTimePerPoint()
end
function PitchCorrectedTake:getPitchPointsFromExtState()
    local pointString = reaper.GetExtState("Alkamist_PitchCorrection", "PITCHDATA")

    self.pitches.points = {}

    local i = 1
    for line in pointString:gmatch("([^\r\n]+)") do
        local values =     getValuesFromStringLine(line)
        local pointTime =  values[1] - self.startOffset
        local point = {
            time =       pointTime,
            --sourceTime = getSourcePosition(analysisTake, pointTime),
            pitch =      values[2],
            rms =        values[3]
        }
        self.pitches.points[i] = point
        i = i + 1
    end
end
function PitchCorrectedTake:analyzePitch(settings)
    local analyzerID = getEELCommandID("Pitch Analyzer")
    if not analyzerID then
        reaper.MB("Pitch Analyzer.eel not found!", "Error!", 0)
        return 0
    end

    local leftBound =      getSourcePosition(self.pointer, 0.0)
    local rightBound =     getSourcePosition(self.pointer, self.length)
    local analysisLength = rightBound - leftBound
    local analysisItem =   reaper.AddMediaItemToTrack(self.track)
    local analysisTake =   reaper.AddTakeToMediaItem(analysisItem)

    --reaper.SetMediaItemTake_Source(analysisTake, self.source)
    --reaper.SetMediaItemTakeInfo_Value(analysisTake, "D_STARTOFFS", leftBound)
    --reaper.SetMediaItemInfo_Value(analysisItem, "D_LENGTH", analysisLength)
    --reaper.SetMediaItemInfo_Value(analysisItem, "B_LOOPSRC", 0)

    --local analysisTakeGUID = reaper.BR_GetMediaItemTakeGUID(analysisTake)
    reaper.SetExtState("Alkamist_PitchCorrection", "TAKEGUID",    self.GUID,                false)
    reaper.SetExtState("Alkamist_PitchCorrection", "WINDOWSTEP",  settings.windowStep,       true)
    reaper.SetExtState("Alkamist_PitchCorrection", "MINFREQ",     settings.minimumFrequency, true)
    reaper.SetExtState("Alkamist_PitchCorrection", "MAXFREQ",     settings.maximumFrequency, true)
    reaper.SetExtState("Alkamist_PitchCorrection", "YINTHRESH",   settings.YINThresh,        true)
    reaper.SetExtState("Alkamist_PitchCorrection", "OVERLAP",     settings.overlap,          true)
    reaper.SetExtState("Alkamist_PitchCorrection", "LOWRMSLIMDB", settings.lowRMSLimitdB,    true)

    mainCommand(analyzerID)

    self:getPitchPointsFromExtState()
    --reaper.DeleteTrackMediaItem(self.track, analysisItem)

    self:updateMinimumTimePerPoint()
    self:clearEnvelope()
end
function PitchCorrectedTake:updateMinimumTimePerPoint()
    self.minimumTimePerPoint = self.length
    local points = self.pitches.points
    local numberOfPoints = #points
    for i = 1, numberOfPoints do
        local point =     points[i]
        local nextPoint = points[i + 1]
        if nextPoint then
            local timeFromLastPoint = nextPoint.time - point.time
            self.minimumTimePerPoint = math.min(self.minimumTimePerPoint, timeFromLastPoint)
        end
    end
end
function PitchCorrectedTake:correctSelectedPitchPoints()
    local corrections = self.corrections.points
    local pitchPoints = self.pitches.points
    for i = 1, #corrections do
        local correction =     corrections[i]
        local nextCorrection = corrections[i + 1]

        if correction.isSelected then
            if correction.isActive and nextCorrection then
                correctPitchPoints(correction, nextCorrection, pitchPoints, self.envelope, self.playrate)
            end

            local previousCorrection = corrections[i - 1]
            if previousCorrection and previousCorrection.isActive then
                correctPitchPoints(previousCorrection, correction, pitchPoints, self.envelope, self.playrate)
            end
        end
    end
    reaper.Envelope_SortPoints(self.envelope)
    reaper.UpdateArrange()
end
function PitchCorrectedTake:correctAllPitchPoints()
    self:clearEnvelope()
    local corrections = self.corrections.points
    local pitchPoints = self.pitches.points
    for i = 1, #corrections do
        local correction =     corrections[i]
        local nextCorrection = corrections[i + 1]

        addEdgePointsToCorrection(i, corrections, self.envelope, self.playrate)
        if correction.isActive and nextCorrection then
            correctPitchPoints(correction, nextCorrection, pitchPoints, self.envelope, self.playrate)
        end
    end
    reaper.Envelope_SortPoints(self.envelope)
    reaper.UpdateArrange()
end
function PitchCorrectedTake:clearEnvelope()
    reaper.DeleteEnvelopePointRange(self.envelope, 0, self.length * self.playrate)
    reaper.Envelope_SortPoints(self.envelope)
    reaper.UpdateArrange()
end
function PitchCorrectedTake:insertPitchCorrectionPoint(point)
    point.driftTime =       point.driftTime       or 0.12
    point.driftCorrection = point.driftCorrection or 1.0
    point.modCorrection =   point.modCorrection   or 0.0
    self.corrections:insertPoint(point)
end

return PitchCorrectedTake