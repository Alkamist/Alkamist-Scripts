local reaper = reaper
local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local PolyLine = require("GFX.PolyLine")
local Json = require("Json")

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
        local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
        return (sourceTime - startOffset) / playrate
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
                reaper.InsertEnvelopePoint(envelope, pitchPoint.time * playrate, driftCorrection + modCorrection, 0, 0, false, true)
                addZeroPointsToEnvelope(i, pitchPoints, 0.2, 0.005, envelope, playrate)
            end
        end
    end
end

--==============================================================
--== Saving Logic ==============================================
--==============================================================

local function encodeSaveString(tableToEncode, memberNames, memberDefaults)
    local saveTable = {}
    for i = 1, #tableToEncode do
        local point = tableToEncode[i]
        saveTable[i] = {}
        for j = 1, #memberNames do
            local name = memberNames[j]
            saveTable[i][name] = point[name] or memberDefaults[j] or 0
        end
    end
    return Json.encode(saveTable)
end
local function decodeSaveString(stringToDecode, memberNames, memberDefaults)
    local decodedTable = Json.decode(stringToDecode)
    local outputTable = {}
    for i = 1, #decodedTable do
        local point = decodedTable[i]
        outputTable[i] = {}
        for j = 1, #memberNames do
            local name = memberNames[j]
            outputTable[i][name] = point[name] or memberDefaults[j] or 0
        end
    end
    return outputTable
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

    self.numberOfAnalysisLoops  = 0
    self.analysisLoopsCompleted = 0

    self.newPointsHaveBeenInitialized = true

    return self
end

function PitchCorrectedTake:clear()
    self.pointer =            nil
    self.takeName =           ""
    self.takeGUID =           nil
    self.takeSource =         nil
    self.takeFileName =       ""
    self.playrate =           1.0
    self.startOffset =        0.0
    self.envelope =           nil
    self.takeSourceLength =   0.0
    self.item =               nil
    self.track =              nil
    self.length =             0.0
    self.leftTime =           0.0
    self.rightTime =          0.0
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

    self.pointer =      take
    self.name =         reaper.GetTakeName(self.pointer)
    self.GUID =         reaper.BR_GetMediaItemTakeGUID(self.pointer)
    self.source =       reaper.GetMediaItemTake_Source(self.pointer)
    self.fileName =     reaper.GetMediaSourceFileName(self.source, ""):match("[^/\\]+$")
    self.sampleRate =   reaper.GetMediaSourceSampleRate(self.source)
    self.playrate =     reaper.GetMediaItemTakeInfo_Value(self.pointer, "D_PLAYRATE")
    self.startOffset =  getSourceTime(self.pointer, 0.0)
    self.envelope =     self:activateEnvelope()
    _, _, self.takeSourceLength = reaper.PCM_Source_GetSectionInfo(self.source)

    self.item =         reaper.GetMediaItemTake_Item(self.pointer)
    self.track =        reaper.GetMediaItem_Track(self.item)
    self.length =       reaper.GetMediaItemInfo_Value(self.item, "D_LENGTH")
    self.leftTime =     reaper.GetMediaItemInfo_Value(self.item, "D_POSITION")
    self.rightTime =    self.leftTime + self.length

    self:loadPitchPoints()
    self.corrections.points = {}

    self:clearEnvelope()
end
function PitchCorrectedTake:removeDuplicatePitchPoints(tolerance)
    local tolerance = tolerance or 0.0001
    local newPoints = {}
    local points = self.pitches.points
    for i = 1, #points do
        local point = points[i]
        local pointIsDuplicate = false
        for j = 1, #newPoints do
            if math.abs(point.time - newPoints[j].time) < tolerance then
                pointIsDuplicate = true
            end
        end
        if not pointIsDuplicate then
            newPoints[#newPoints + 1] = point
        end
    end
    self.pitches.points = newPoints
end
function PitchCorrectedTake:getPitchPointsFromExtState()
    local pointString = reaper.GetExtState("AlkamistPitchCorrection", "PITCHPOINTS")

    local points = self.pitches.points

    for line in pointString:gmatch("([^\r\n]+)") do
        local values =    getValuesFromStringLine(line)
        local pointTime = values[1]
        local point = {
            time =       getRealTime(self.pointer, pointTime),
            sourceTime = pointTime,
            pitch =      values[2],
            --rms =        values[3]
        }
        points[#points + 1] = point
    end
end
function PitchCorrectedTake:prepareToAnalyzePitch(settings)
    self.analyzerID = getEELCommandID("WritePitchPointsToExtState")
    if not self.analyzerID then
        reaper.MB("WritePitchPointsToExtState.eel not found!", "Error!", 0)
        return 0
    end

    self.pitches.points = {}
    self.newPointsHaveBeenInitialized = false

    --local leftBound =      getSourceTime(self.pointer, 0.0)
    --local rightBound =     getSourceTime(self.pointer, self.length)
    --local analysisLength = rightBound - leftBound
    --local analysisItem =   reaper.AddMediaItemToTrack(self.track)
    --local analysisTake =   reaper.AddTakeToMediaItem(analysisItem)
    --reaper.SetMediaItemTake_Source(analysisTake, self.source)
    --reaper.SetMediaItemTakeInfo_Value(analysisTake, "D_STARTOFFS", leftBound)
    --reaper.SetMediaItemInfo_Value(analysisItem, "D_LENGTH", analysisLength)
    --reaper.SetMediaItemInfo_Value(analysisItem, "B_LOOPSRC", 0)
    --local analysisTakeGUID = reaper.BR_GetMediaItemTakeGUID(analysisTake)

    reaper.SetExtState("AlkamistPitchCorrection", "TAKEGUID",         self.GUID,                 false)
    reaper.SetExtState("AlkamistPitchCorrection", "WINDOWSTEP",       settings.windowStep,       false)
    reaper.SetExtState("AlkamistPitchCorrection", "WINDOWOVERLAP",    settings.windowOverlap,    false)
    reaper.SetExtState("AlkamistPitchCorrection", "MINIMUMFREQUENCY", settings.minimumFrequency, false)
    reaper.SetExtState("AlkamistPitchCorrection", "MAXIMUMFREQUENCY", settings.maximumFrequency, false)
    reaper.SetExtState("AlkamistPitchCorrection", "THRESHOLD",        settings.threshold,        false)
    reaper.SetExtState("AlkamistPitchCorrection", "MINIMUMRMSDB",     settings.minimumRMSdB,     false)

    local numberOfPitchPointsPerLoop = 10
    self.analysisStartTime =           0.0
    self.analysisTimeWindow =          numberOfPitchPointsPerLoop * settings.windowStep / settings.windowOverlap
    self.numberOfAnalysisLoops =       math.ceil(self.length / self.analysisTimeWindow)
    self.analysisLoopsCompleted =      0

    --reaper.DeleteTrackMediaItem(self.track, analysisItem)

    self:clearEnvelope()
end
function PitchCorrectedTake:analyzePitch()
    self.isAnalyzingPitch = self.analysisLoopsCompleted < self.numberOfAnalysisLoops
    if self.isAnalyzingPitch then
        reaper.SetExtState("AlkamistPitchCorrection", "STARTTIME",  self.analysisStartTime,  false)
        reaper.SetExtState("AlkamistPitchCorrection", "TIMEWINDOW", self.analysisTimeWindow, false)

        mainCommand(self.analyzerID)
        self:getPitchPointsFromExtState()

        self.analysisStartTime = self.analysisStartTime + self.analysisTimeWindow
        self.analysisLoopsCompleted = self.analysisLoopsCompleted + 1
    else
        if not self.newPointsHaveBeenInitialized then
            self:removeDuplicatePitchPoints()
            self:savePitchPoints()
            self.newPointsHaveBeenInitialized = true
        end
    end
end
function PitchCorrectedTake:updatePitchPointTimes()
    local points = self.pitches.points
    for i = 1, #points do
        local point = points[i]
        point.time = getRealTime(self.pointer, point.sourceTime)
    end
end
function PitchCorrectedTake:loadPitchPoints()
    local pathName = reaper.GetProjectPath("") .. "\\AlkamistPitchCorrection"
    local fullFileName = pathName .. "\\" .. self.fileName .. ".pitch"

    local file = io.open(fullFileName)
    if file then
        local saveString = file:read("*all")
        file:close()
        self.pitches.points = decodeSaveString(saveString,
                                               {"sourceTime", "pitch"},
                                               {0.0,          0.0})
        self:updatePitchPointTimes()
    end
end
function PitchCorrectedTake:savePitchPoints()
    local pathName = reaper.GetProjectPath("") .. "\\AlkamistPitchCorrection"
    local fullFileName = pathName .. "\\" .. self.fileName .. ".pitch"
    reaper.RecursiveCreateDirectory(pathName, 0)

    local saveString = encodeSaveString(self.pitches.points,
                                        {"sourceTime", "pitch"},
                                        {0.0,          0.0})

    local file, err = io.open(fullFileName, "w")
    file:write(saveString)
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