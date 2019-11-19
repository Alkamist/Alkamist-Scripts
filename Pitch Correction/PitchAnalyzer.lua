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

local PitchAnalyzer = {}
function PitchAnalyzer:new(parameters)
    local parameters = parameters or {}
    local self = TimeSeries:new(parameters)

    local _take = Take:new{ pointer = parameters.pointer }
    local _pathName = reaper.GetProjectPath("") .. "\\AlkamistPitchCorrection"
    local _pointMembers = {
        sourceTime = 0,
        pitch = 0
    }
    local _settings = {
        windowStep = 0.04,
        windowOverlap = 2.0,
        minimumFrequency = 80,
        maximumFrequency = 1000,
        threshold = 0.2,
        minimumRMSdB = -60.0
    }
    local _analysisStartTime = 0.0
    local _analyzeFullSource = false
    local _numberOfPointsToAnalyzePerLoop = 10
    local _isAnalyzingPitch = false
    local _newPointsHaveBeenInitialized = true
    local function _getAnalyzerID()
        local analyzerID = getEELCommandID("WritePitchPointsToExtState")
        if not analyzerID then
            reaper.MB("WritePitchPointsToExtState.eel not found!", "Error!", 0)
            return
        end
        return analyzerID
    end
    local function _getAnalysisEndTime()
        if _analyzeFullSource then
            return _take:getSourceLength()
        end
        return _take:getSourceTime(_take:getLength())
    end
    local function _getAnalysisTimeWindow()
        local timeWindow = _numberOfPointsToAnalyzePerLoop * _settings.windowStep / _settings.windowOverlap
        return math.min(timeWindow, _getAnalysisEndTime() - _analysisStartTime)
    end
    local function _getAnalysisLength()
        return _getAnalysisEndTime() - _analysisStartTime
    end
    local function _getNumberOfAnalysisLoopsRemaining()
        local timeWindow = _getAnalysisTimeWindow()
        if timeWindow == 0 then return 0 end
        if _analyzeFullSource then
            return math.ceil(_take:getSourceLength() / timeWindow)
        end
        return math.ceil(_getAnalysisLength() / timeWindow)
    end
    local function _getPointsFromExtState()
        local pointString = reaper.GetExtState("AlkamistPitchCorrection", "PITCHPOINTS")
        for line in pointString:gmatch("([^\r\n]+)") do
            local values = getValuesFromStringLine(line)
            local pointTime = values[1]
            self:insertPoint{
                time = _take:getRealTime(pointTime),
                sourceTime = pointTime,
                pitch = values[2],
                --rms = values[3]
            }
        end
    end
    local function _getFileName()
        local takeFileName = _take:getFileName()
        if takeFileName then return takeFileName .. ".pitch" end
    end

    function self:setTakePointer(pointer)
        _take:setPointer(pointer)
    end
    function self:prepareToAnalyzePitch(analyzeFullSource)
        if _take == nil then return end
        if _take:isMIDI() then return end

        local settings = _settings
        reaper.SetExtState("AlkamistPitchCorrection", "TAKEGUID", _take:getGUID(), false)
        reaper.SetExtState("AlkamistPitchCorrection", "WINDOWSTEP", settings.windowStep, false)
        reaper.SetExtState("AlkamistPitchCorrection", "WINDOWOVERLAP", settings.windowOverlap, false)
        reaper.SetExtState("AlkamistPitchCorrection", "MINIMUMFREQUENCY", settings.minimumFrequency, false)
        reaper.SetExtState("AlkamistPitchCorrection", "MAXIMUMFREQUENCY", settings.maximumFrequency, false)
        reaper.SetExtState("AlkamistPitchCorrection", "THRESHOLD", settings.threshold, false)
        reaper.SetExtState("AlkamistPitchCorrection", "MINIMUMRMSDB", settings.minimumRMSdB, false)

        _analyzeFullSource = analyzeFullSource
        _isAnalyzingPitch = true
        _newPointsHaveBeenInitialized = false
        if _analyzeFullSource then
            _analysisStartTime = 0.0
            self:clearAllPoints()
        else
            _analysisStartTime = _take:getStartOffset()
            self:clearPointsWithinTimeRange(0.0, _take:getLength())
        end
    end
    function self:analyzePitch()
        if _isAnalyzingPitch then
            local analysisTimeWindow = _getAnalysisTimeWindow()

            reaper.SetExtState("AlkamistPitchCorrection", "STARTTIME",  _analysisStartTime,  false)
            reaper.SetExtState("AlkamistPitchCorrection", "TIMEWINDOW", analysisTimeWindow, false)

            mainCommand(_getAnalyzerID())
            _getPointsFromExtState()

            _analysisStartTime = _analysisStartTime + analysisTimeWindow
            _isAnalyzingPitch = _getNumberOfAnalysisLoopsRemaining() > 0
        else
            if not _newPointsHaveBeenInitialized then
                self:removeDuplicatePoints()
                self:savePoints(_pathName, _getFileName(), _pointMembers)
                _newPointsHaveBeenInitialized = true
            end
        end
    end
    function self:updatePointRealTimes()
        local points = self:getPoints()
        for i = 1, #points do
            local point = points[i]
            point.time = _take:getRealTime(point.sourceTime)
        end
    end
    local _timeSeriesLoadPoints = self.loadPoints
    function self:loadPoints(...)
        _timeSeriesLoadPoints(self, ...)
        self:updatePointRealTimes()
    end
    function self:loadPointsFromTakeFile()
        if _take:getPointer() then
            self:loadPoints(_pathName, _getFileName(), _pointMembers)
        end
    end

    return self
end

return PitchAnalyzer