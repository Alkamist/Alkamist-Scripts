local GUI = require("GUI")
local TimeSeries = require("TimeSeries")
local Reaper = require("Reaper")

local tonumber = tonumber
local reaper = reaper
local io = io

local pitchAnalysisSettings = {
    windowStep = 0.04,
    windowOverlap = 2,
    minimumFrequency = 80,
    maximumFrequency = 1000,
    threshold = 0.2,
    minimumRMSdB = -60
}

local function getValuesFromStringLine(str)
    local values = {}
    local i = 1
    for value in str:gmatch("[%.%-%d]+") do
        values[i] = tonumber(value)
        i = i + 1
    end
    return values
end
local function getPitchPointsFromExtState(self)
    local points = {}
    local pointString = reaper.GetExtState("AlkamistPitchCorrection", "PITCHPOINTS")
    for line in pointString:gmatch("([^\r\n]+)") do
        local values = getValuesFromStringLine(line)
        local pointTime = values[1]
        points[#points + 1] = {
            time = Reaper.getTakeRealTime(self.takePointer, pointTime),
            sourceTime = pointTime,
            pitch = values[2],
            --rms = values[3]
        }
    end
    return points
end
local function prepareToAnalyzePitch(self)
    if self.takePointer == nil then return end
    if self.takeIsMIDI then return end

    reaper.SetExtState("AlkamistPitchCorrection", "TAKEGUID", self.takeGUID, false)
    reaper.SetExtState("AlkamistPitchCorrection", "WINDOWSTEP", pitchAnalysisSettings.windowStep, false)
    reaper.SetExtState("AlkamistPitchCorrection", "WINDOWOVERLAP", pitchAnalysisSettings.windowOverlap, false)
    reaper.SetExtState("AlkamistPitchCorrection", "MINIMUMFREQUENCY", pitchAnalysisSettings.minimumFrequency, false)
    reaper.SetExtState("AlkamistPitchCorrection", "MAXIMUMFREQUENCY", pitchAnalysisSettings.maximumFrequency, false)
    reaper.SetExtState("AlkamistPitchCorrection", "THRESHOLD", pitchAnalysisSettings.threshold, false)
    reaper.SetExtState("AlkamistPitchCorrection", "MINIMUMRMSDB", pitchAnalysisSettings.minimumRMSdB, false)

    self.isAnalyzingPitch = true
    self.newPitchPointsHaveBeenInitialized = false

    if self.shouldAnalyzeFullTakeSource then
        self.pitchAnalysisStartTime = 0.0
        self.takePitchPoints = {}
    else
        self.pitchAnalysisStartTime = self.takeStartOffset
        --TimeSeries.clearPointsWithinTimeRange(self.takePitchPoints, 0.0, self.length)
    end
end
local function analyzePitch(self)
    if self.isAnalyzingPitch then
        reaper.SetExtState("AlkamistPitchCorrection", "STARTTIME",  self.pitchAnalysisStartTime,  false)
        reaper.SetExtState("AlkamistPitchCorrection", "TIMEWINDOW", self.pitchAnalysisTimeWindow, false)

        Reaper.mainCommand(self.pitchAnalyzerID)
        getPitchPointsFromExtState(self)

        self.pitchAnalysisStartTime = self.pitchAnalysisStartTime + self.pitchAnalysisTimeWindow
        self.isAnalyzingPitch = self.numberOfAnalysisLoopsRemaining > 0
    else
        if self.takePitchPoints and not self.newPitchPointsHaveBeenInitialized then
            TimeSeries.removeDuplicatePoints(self.takePitchPoints)
            --TimeSeries.savePoints(self.takePitchPoints, self.pitchSavingPath, self.pitchSavingFileName, self.pitchPointMembers)
            self.newPitchPointsHaveBeenInitialized = true
        end
    end
end

local TakePitchPoints = {}

function TakePitchPoints:requires()
    return self.TakePitchPoints
end
function TakePitchPoints:getDefaults()
    local defaults = {}

    defaults.pitchAnalyzerID = Reaper.getEELCommandID("WritePitchPointsToExtState")
    if not defaults.pitchAnalyzerID then
        reaper.MB("WritePitchPointsToExtState.eel not found!", "Error!", 0)
        return
    end

    defaults.pitchAnalysisStartTime = 0.0
    defaults.shouldAnalyzeFullTakeSource = false
    defaults.numberOfPointsToAnalyzePerLoop = 10
    return defaults
end
function TakePitchPoints:update(dt)
    local timeWindow = self.numberOfPointsToAnalyzePerLoop * pitchAnalysisSettings.windowStep / pitchAnalysisSettings.windowOverlap
    self.pitchAnalysisTimeWindow = math.min(timeWindow, self.pitchAnalysisEndTime - self.pitchAnalysisStartTime)

    if self.shouldAnalyzeFullTakeSource then
        self.pitchAnalysisEndTime = self.sourceLength
    else
        self.pitchAnalysisEndTime = Reaper.getTakeSourceTime(self.takePointer, self.itemLength)
    end

    if self.startAnalyzingPitch == true then
        prepareToAnalyzePitch(self)
        self.startAnalyzingPitch = false
    end
    analyzePitch(self)
    self.points = self.takePitchPoints
end

return TakePitchPoints