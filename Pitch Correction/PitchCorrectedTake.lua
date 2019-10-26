local reaper = reaper

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local PolyLine = require("GFX.PolyLine")

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




local PitchCorrectedTake = {}

function PitchCorrectedTake:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.pitches     = PolyLine:new()
    self.corrections = PolyLine:new()

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
    mainCommand("_S&M_TAKEENVSHOW8") -- Hide take pitch envelope
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
    self.takeName =     reaper.GetTakeName(self.pointer)
    self.takeGUID =     reaper.BR_GetMediaItemTakeGUID(self.pointer)
    self.takeSource =   reaper.GetMediaItemTake_Source(self.pointer)
    self.takeFileName = reaper.GetMediaSourceFileName(self.takeSource, ""):match("[^/\\]+$")
    self.playrate =     reaper.GetMediaItemTakeInfo_Value(self.pointer, "D_PLAYRATE")
    self.startOffset =  getSourcePosition(self.pointer, 0.0)
    self.envelope =     self:activateEnvelope()
    _, _, self.takeSourceLength = reaper.PCM_Source_GetSectionInfo(self.takeSource)

    self.item =         reaper.GetMediaItemTake_Item(self.pointer)
    self.track =        reaper.GetMediaItem_Track(self.item)
    self.length =       reaper.GetMediaItemInfo_Value(self.item, "D_LENGTH")
    self.leftTime =     reaper.GetMediaItemInfo_Value(self.item, "D_POSITION")
    self.rightTime =    self.leftTime + self.length

    self.pitches.points     = {}
    self.corrections.points = {}
    --self:loadSavedPoints()
    --self.minTimePerPoint = self:getMinTimePerPoint()
    --self.minSourceTimePerPoint = self:getMinSourceTimePerPoint()
end
function PitchCorrectedTake:getPitchPointsFromExtState(analysisTake)
    local pointString = reaper.GetExtState("Alkamist_PitchCorrection", "PITCHDATA")

    self.pitches.points = {}

    for line in pointString:gmatch("([^\r\n]+)") do
        local values =     getValuesFromStringLine(line)
        local pointTime =  values[1] - self.startOffset
        local point = {
            time =       pointTime,
            sourceTime = getSourcePosition(analysisTake, pointTime),
            pitch =      values[2],
            rms =        values[3]
        }
        self.pitches.points[#self.pitches.points + 1] = point
    end
end
function PitchCorrectedTake:analyzePitch(settings)
    local analyzerID = Reaper.getEELCommandID("Pitch Analyzer")
    if not analyzerID then
        reaper.MB("Pitch Analyzer.eel not found!", "Error!", 0)
        return 0
    end

    local leftBound =      getSourcePosition(self.pointer, 0.0)
    local rightBound =     getSourcePosition(self.pointer, self.length)
    local analysisLength = rightBound - leftBound
    local analysisItem =   reaper.AddMediaItemToTrack(self.track)
    local analysisTake =   reaper.AddTakeToMediaItem(analysisItem)

    reaper.SetMediaItemTake_Source(analysisTake, self.takeSource)
    reaper.SetMediaItemTakeInfo_Value(analysisTake, "D_STARTOFFS", leftBound)
    reaper.SetMediaItemInfo_Value(analysisItem, "D_LENGTH", analysisLength)
    reaper.SetMediaItemInfo_Value(analysisItem, "B_LOOPSRC", 0)

    local analysisTakeGUID = reaper.BR_GetMediaItemTakeGUID(analysisTake)
    reaper.SetExtState("Alkamist_PitchCorrection", "TAKEGUID",    takeGUID,                  false)
    reaper.SetExtState("Alkamist_PitchCorrection", "WINDOWSTEP",  settings.windowStep,       true)
    reaper.SetExtState("Alkamist_PitchCorrection", "MINFREQ",     settings.minimumFrequency, true)
    reaper.SetExtState("Alkamist_PitchCorrection", "MAXFREQ",     settings.maximumFrequency, true)
    reaper.SetExtState("Alkamist_PitchCorrection", "YINTHRESH",   settings.YINThresh,        true)
    reaper.SetExtState("Alkamist_PitchCorrection", "OVERLAP",     settings.overlap,          true)
    reaper.SetExtState("Alkamist_PitchCorrection", "LOWRMSLIMDB", settings.lowRMSLimitdB,    true)

    mainCommand(analyzerID)

    self:getPitchPointsFromExtState(analysisTake)
    --self:savePoints()
    --self:loadSavedPoints()
    --self.minTimePerPoint = self:getMinTimePerPoint()
    --self.minSourceTimePerPoint = self:getMinSourceTimePerPoint()

    reaper.DeleteTrackMediaItem(self.track, analysisItem)
end

return PitchCorrectedTake