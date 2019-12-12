local Reaper = require("Reaper")

local reaper = reaper

local PitchEditorTake = {}

function PitchEditorTake:requires()
    return self.PitchEditorTake
end
function PitchEditorTake:getDefaults()
    local defaults = {}
    defaults.itemLength = 0.0
    defaults.itemLeftTime = 0.0
    defaults.itemRightTime = 0.0
    defaults.trackPointer = nil
    defaults.takePointer = nil
    defaults.takeName = nil
    defaults.takeGUID = nil
    defaults.takePlayrate = nil
    defaults.takeStartOffset = nil
    defaults.takeIsMIDI = nil
    defaults.takePitchEnvelope = nil
    defaults.takeSource = nil
    defaults.takeFileName = nil
    defaults.takeSampleRate = nil
    defaults.takeSourceLength = nil
    return defaults
end
function PitchEditorTake:update()
    self.itemPointer = reaper.GetSelectedMediaItem(0, 0)
    if self.itemPointer then
        self.itemLength = reaper.GetMediaItemInfo_Value(self.itemPointer, "D_LENGTH")
        self.itemLeftTime = reaper.GetMediaItemInfo_Value(self.itemPointer, "D_POSITION")
        self.itemRightTime = self.itemLeftTime + self.itemLength

        self.trackPointer = reaper.GetMediaItem_Track(self.itemPointer)

        self.takePointer = reaper.GetActiveTake(self.itemPointer)
        self.takeName = reaper.GetTakeName(self.takePointer)
        self.takeGUID = reaper.BR_GetMediaItemTakeGUID(self.takePointer)
        self.takePlayrate = reaper.GetMediaItemTakeInfo_Value(self.takePointer, "D_PLAYRATE")
        self.takeStartOffset = Reaper.getTakeSourceTime(self.takePointer, 0.0)
        self.takeIsMIDI = reaper.TakeIsMIDI(self.takePointer)
        self.takePitchEnvelope = Reaper.getTakePitchEnvelope(self.takePointer)

        self.takeSource = reaper.GetMediaItemTake_Source(self.takePointer)
        self.takeFileName = reaper.GetMediaSourceFileName(self.takeSource, ""):match("[^/\\]+$")
        self.takeSampleRate = reaper.GetMediaSourceSampleRate(self.takeSource)
        local _, _, sourceLength = reaper.PCM_Source_GetSectionInfo(self.takeSource)
        self.takeSourceLength = sourceLength
    else
        self.itemLength = 0.0
        self.itemLeftTime = 0.0
        self.itemRightTime = 0.0
        self.trackPointer = nil
        self.takePointer = nil
        self.takeName = nil
        self.takeGUID = nil
        self.takePlayrate = nil
        self.takeStartOffset = nil
        self.takeIsMIDI = nil
        self.takePitchEnvelope = nil
        self.takeSource = nil
        self.takeFileName = nil
        self.takeSampleRate = nil
        self.takeSourceLength = nil
    end
end

return PitchEditorTake