local reaper = reaper
local math = math
local io = io

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Take = require("Pitch Correction.Take")
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

local TakeWithPitchPoints = {}
function TakeWithPitchPoints:new(object)
    local self = Take:new(self)

    self.pitches = TimeSeries:new()
    self.pitchSavingPath = reaper.GetProjectPath("") .. "\\AlkamistPitchCorrection"
    self.pitchSavingFileName = {
            get = function(self)
            local fileName = self.fileName
            if fileName then return fileName .. ".pitch" end
        end
    }
    self.pitchPointMembers = {
        sourceTime = 0,
        pitch = 0
    }
    self.pitchAnalysisSettings = {
        windowStep = 0.04,
        windowOverlap = 2.0,
        minimumFrequency = 80,
        maximumFrequency = 1000,
        threshold = 0.2,
        minimumRMSdB = -60.0
    }
    self.pitchAnalyzerID = {
        get = function(self)
            local pitchAnalyzerID = getEELCommandID("WritePitchPointsToExtState")
            if not pitchAnalyzerID then
                reaper.MB("WritePitchPointsToExtState.eel not found!", "Error!", 0)
                return
            end
            return pitchAnalyzerID
        end
    }
    self.pitchAnalysisStartTime = 0.0
    self.shouldAnalyzeFullTakeSource = false
    self.numberOfPointsToAnalyzePerLoop = 10
    self.pitchAnalysisTimeWindow = {
        get = function(self)
            local settings = self.pitchAnalysisSettings
            local timeWindow = self.numberOfPointsToAnalyzePerLoop * settings.windowStep / settings.windowOverlap
            return math.min(timeWindow, self.pitchAnalysisEndtime - self.pitchAnalysisStartTime)
        end
    }
    self.pitchAnalysisEndtime = {
        get = function(self)
            if self.shouldAnalyzeFullTakeSource then
                return self.sourceLength
            end
            return self:getSourceTime(self.length)
        end
    }
    self.pitchAnalysisLength = { get = function(self) return self.pitchAnalysisEndtime - self.pitchAnalysisStartTime end }
    self.numberOfAnalysisLoopsRemaining = {
        get = function(self)
            local timeWindow = self.pitchAnalysisTimeWindow
            if timeWindow == 0 then return 0 end
            if self.shouldAnalyzeFullTakeSource then
                return math.ceil(self.sourceLength / timeWindow)
            end
            return math.ceil(self.pitchAnalysisLength / timeWindow)
        end
    }
    self.isAnalyzingPitch = false
    self.newPitchPointsHaveBeenInitialized = true

    if object then for k, v in pairs(object) do self[k] = v end end
    return self
end

function TakeWithPitchPoints:getPitchPointsFromExtState()
    local pointString = reaper.GetExtState("AlkamistPitchCorrection", "PITCHPOINTS")
    for line in pointString:gmatch("([^\r\n]+)") do
        local values = getValuesFromStringLine(line)
        local pointTime = values[1]
        self.pitches.points[#self.pitches.points + 1] = {
            time = self:getRealTime(pointTime),
            sourceTime = pointTime,
            pitch = values[2],
            --rms = values[3]
        }
    end
end
function TakeWithPitchPoints:prepareToAnalyzePitch(shouldAnalyzeFullTakeSource)
    if self.pointer == nil then return end
    if self.isMIDI then return end

    local settings = self.pitchAnalysisSettings
    reaper.SetExtState("AlkamistPitchCorrection", "TAKEGUID", self.GUID, false)
    reaper.SetExtState("AlkamistPitchCorrection", "WINDOWSTEP", settings.windowStep, false)
    reaper.SetExtState("AlkamistPitchCorrection", "WINDOWOVERLAP", settings.windowOverlap, false)
    reaper.SetExtState("AlkamistPitchCorrection", "MINIMUMFREQUENCY", settings.minimumFrequency, false)
    reaper.SetExtState("AlkamistPitchCorrection", "MAXIMUMFREQUENCY", settings.maximumFrequency, false)
    reaper.SetExtState("AlkamistPitchCorrection", "THRESHOLD", settings.threshold, false)
    reaper.SetExtState("AlkamistPitchCorrection", "MINIMUMRMSDB", settings.minimumRMSdB, false)

    self.shouldAnalyzeFullTakeSource = shouldAnalyzeFullTakeSource
    self.isAnalyzingPitch = true
    self.newPitchPointsHaveBeenInitialized = false
    if self.shouldAnalyzeFullTakeSource then
        self.pitchAnalysisStartTime = 0.0
        self.pitches.points = {}
    else
        self.pitchAnalysisStartTime = self.startOffset
        self.pitches:clearPointsWithinTimeRange(0.0, self.length)
    end
end
function TakeWithPitchPoints:analyzePitch()
    if self.isAnalyzingPitch then
        local pitchAnalysisTimeWindow = self.pitchAnalysisTimeWindow

        reaper.SetExtState("AlkamistPitchCorrection", "STARTTIME",  self.pitchAnalysisStartTime,  false)
        reaper.SetExtState("AlkamistPitchCorrection", "TIMEWINDOW", pitchAnalysisTimeWindow, false)

        mainCommand(self.pitchAnalyzerID)
        self:getPitchPointsFromExtState()

        self.pitchAnalysisStartTime = self.pitchAnalysisStartTime + pitchAnalysisTimeWindow
        self.isAnalyzingPitch = self.numberOfAnalysisLoopsRemaining > 0
    else
        if not self.newPitchPointsHaveBeenInitialized then
            self.pitches:removeDuplicatePoints()
            self.pitches:savePoints(self.pitchSavingPath, self.pitchSavingFileName, self.pitchPointMembers)
            self.newPitchPointsHaveBeenInitialized = true
        end
    end
end
function TakeWithPitchPoints:updatePitchPointRealTimes()
    local points = self.pitches.points
    for i = 1, #points do
        local point = points[i]
        point.time = self:getRealTime(point.sourceTime)
    end
end
function TakeWithPitchPoints:loadPitchPoints(...)
    self.pitches:loadPoints(...)
    self:updatePitchPointRealTimes()
end
function TakeWithPitchPoints:loadPitchPointsFromTakeFile()
    if self.pointer then
        self:loadPitchPoints(self.pitchSavingPath, self.pitchSavingFileName, self.pitchPointMembers)
    end
end

return TakeWithPitchPoints