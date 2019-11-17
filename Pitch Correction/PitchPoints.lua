local reaper = reaper
local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Proxy = require("Proxy")
local TimeSeries = require("Pitch Correction.TimeSeries")

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
local function getValuesFromStringLine(str)
    local values = {}
    local i = 1
    for value in str:gmatch("[%.%-%d]+") do
        values[i] = tonumber(value)
        i = i + 1
    end
    return values
end

local PitchPoints = {}
function PitchPoints:new(initialValues)
    local self = TimeSeries:new(initialValues)

    self.take = nil
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
            return math.min(timeWindow, self.analysisEndTime - self.analysisStartTime)
        end
    }
    self.analysisStartTime = 0
    self.analysisEndTime = {
        get = function(self)
            if self.analyzeFullSource then
                return self.take.sourceLength
            end
            return self.take:getSourceTime(self.length)
        end
    }
    self.analysisLength = { get = function(self) return self.analysisEndTime - self.analysisStartTime end }
    self.numberOfAnalysisLoops = {
        get = function(self)
            local timeWindow = self.analysisTimeWindow
            if timeWindow == 0 then return 0 end
            if self.analyzeFullSource then
                return math.ceil(self.sourceLength / timeWindow)
            end
            return math.ceil(self.analysisLength / timeWindow)
        end
    }
    self.isAnalyzingPitch = false
    self.newPointsHaveBeenInitialized = true

    function self:updateRealTimeOfPoint(point)
        point.time = self.take:getRealTime(point.sourceTime)
    end
    function self:getPointsFromExtState()
        local pointString = reaper.GetExtState("AlkamistPitchCorrection", "PITCHPOINTS")
        local points = self.points
        for line in pointString:gmatch("([^\r\n]+)") do
            local values = getValuesFromStringLine(line)
            local pointTime = values[1]
            local point = {
                time = self.take:getRealTime(pointTime),
                sourceTime = pointTime,
                pitch = values[2],
                --rms = values[3]
            }
            points[#points + 1] = point
        end
    end
    function self:prepareToAnalyzePitch(analyzeFullSource)
        if self.take == nil then return end
        if self.take.isMIDI then return end

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

        self:clearPointsWithinTimeRange(0.0, self.length)
    end
    function self:analyzePitch()
        if self.isAnalyzingPitch then
            local analysisTimeWindow = self.analysisTimeWindow
            reaper.SetExtState("AlkamistPitchCorrection", "STARTTIME",  self.analysisStartTime,  false)
            reaper.SetExtState("AlkamistPitchCorrection", "TIMEWINDOW", analysisTimeWindow, false)

            mainCommand(self.analyzerID)
            self:getPointsFromExtState()

            self.analysisStartTime = self.analysisStartTime + analysisTimeWindow
            self.isAnalyzingPitch = self.numberOfAnalysisLoops > 0
        else
            if not self.newPointsHaveBeenInitialized then
                self:removeDuplicatePoints()
                self.newPointsHaveBeenInitialized = true
            end
        end
    end

    return Proxy:new(self, initialValues)
end

return PitchPoints