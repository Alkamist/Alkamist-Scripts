local Reaper = require("Reaper")

local reaper = reaper

local PitchEditorTake = {}

function PitchEditorTake:new()
    local self = self or {}

    local defaults = {}
    defaults.itemPointer = nil
    defaults.itemLength = 0.0
    defaults.itemLeftTime = 0.0
    defaults.itemRightTime = 0.0
    defaults.trackPointer = nil
    defaults.pointer = nil
    defaults.name = nil
    defaults.GUID = nil
    defaults.playrate = nil
    defaults.startOffset = nil
    defaults.isMIDI = nil
    defaults.pitchEnvelope = nil
    defaults.source = nil
    defaults.fileName = nil
    defaults.sampleRate = nil
    defaults.sourceLength = nil

    for k, v in pairs(defaults) do if self[k] == nil then self[k] = v end end
    for k, v in pairs(PitchEditorTake) do if self[k] == nil then self[k] = v end end
    return self
end
function PitchEditorTake:update()
    self.itemPointer = reaper.GetSelectedMediaItem(0, 0)

    if self.itemPointer then
        self.itemLength = reaper.GetMediaItemInfo_Value(self.itemPointer, "D_LENGTH")
        self.itemLeftTime = reaper.GetMediaItemInfo_Value(self.itemPointer, "D_POSITION")
        self.itemRightTime = self.itemLeftTime + self.itemLength

        self.trackPointer = reaper.GetMediaItem_Track(self.itemPointer)

        self.pointer = reaper.GetActiveTake(self.itemPointer)
        self.name = reaper.GetTakeName(self.pointer)
        self.GUID = reaper.BR_GetMediaItemTakeGUID(self.pointer)
        self.playrate = reaper.GetMediaItemTakeInfo_Value(self.pointer, "D_PLAYRATE")
        self.startOffset = Reaper.getTakeSourceTime(self.pointer, 0.0)
        self.isMIDI = reaper.TakeIsMIDI(self.pointer)
        self.pitchEnvelope = Reaper.getTakePitchEnvelope(self.pointer)

        self.source = reaper.GetMediaItemTake_Source(self.pointer)
        self.fileName = reaper.GetMediaSourceFileName(self.source, ""):match("[^/\\]+$")
        self.sampleRate = reaper.GetMediaSourceSampleRate(self.source)
        local _, _, sourceLength = reaper.PCM_Source_GetSectionInfo(self.source)
        self.sourceLength = sourceLength
    else
        self.itemPointer = nil
        self.itemLength = 0.0
        self.itemLeftTime = 0.0
        self.itemRightTime = 0.0
        self.trackPointer = nil
        self.pointer = nil
        self.name = nil
        self.GUID = nil
        self.playrate = nil
        self.startOffset = nil
        self.isMIDI = nil
        self.pitchEnvelope = nil
        self.source = nil
        self.fileName = nil
        self.sampleRate = nil
        self.sourceLength = nil
    end
end

return PitchEditorTake