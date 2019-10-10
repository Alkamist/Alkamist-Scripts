package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Reaper = require "Pitch Correction.Reaper Functions"
local ReaperPointerWrapper = require "Pitch Correction.Reaper Pointer Wrapper"

------------------ Private Functions ------------------

local function getTakeType(MediaTake)
    if reaper.TakeIsMIDI(MediaTake.pointer) then
        return "midi"
    end

    return "audio"
end

local function getTakeName(MediaTake)
    if MediaTake:getType() == "empty" then
        return reaper.ULT_GetMediaItemNote(MediaTake:getItem())
    end

    return reaper.GetTakeName(MediaTake.pointer)
end

local function getTakeFileName(MediaTake)
    local url = reaper.GetMediaSourceFileName(MediaTake:getSource(), "")
    return url:match("[^/\\]+$")
end

local function getTakePitchEnvelope(MediaTake)
    local pitchEnvelope = reaper.GetTakeEnvelopeByName(MediaTake.pointer, "Pitch")

    if not pitchEnvelope or not reaper.ValidatePtr2(0, pitchEnvelope, "TrackEnvelope*") then
        Reaper.mainCommand("_S&M_TAKEENV10") -- Show and unbypass take pitch envelope
        pitchEnvelope = reaper.GetTakeEnvelopeByName(MediaTake.pointer, "Pitch")
    end

    Reaper.mainCommand("_S&M_TAKEENVSHOW8") -- Hide take pitch envelope

    return pitchEnvelope
end

local function getTakeSourceLength(MediaTake)
    local _, _, takeSourceLength = reaper.PCM_Source_GetSectionInfo(MediaTake.pointer)
    return takeSourceLength
end

------------------ Media Take ------------------

local MediaTake = setmetatable({}, { __index = ReaperPointerWrapper })
function MediaTake:new(object)
    local object = object or {}
    setmetatable(object, { __index = self })
    object:init()
    return object
end

function MediaTake:init()
    self.pointer = self.take
    self.pointerType = "MediaItem_Take*"
    ReaperPointerWrapper.init(self)
end

function MediaTake:getSourcePosition(time)
    if time == nil then return nil end
    local tempMarkerIndex = reaper.SetTakeStretchMarker(self:getTake(), -1, time * self:getPlayrate())
    local _, pos, srcPos = reaper.GetTakeStretchMarker(self:getTake(), tempMarkerIndex)
    reaper.DeleteTakeStretchMarkers(self:getTake(), tempMarkerIndex)
    return srcPos
end

function MediaTake:getItem(shouldRefresh)
    return self:getter(shouldRefresh, "item",
                       function() return reaper.GetMediaItemTake_Item(self.pointer) end)
end

function MediaTake:getType(shouldRefresh)
    return self:getter(shouldRefresh, "type",
                       function() return getTakeType(self) end)
end

function MediaTake:getName(shouldRefresh)
    return self:getter(shouldRefresh, "name",
                       function() return getTakeName(self) end)
end

function MediaTake:getGUID(shouldRefresh)
    return self:getter(shouldRefresh, "GUID",
                       function() return reaper.BR_GetMediaItemTakeGUID(self.pointer) end)
end

function MediaTake:getSource(shouldRefresh)
    return self:getter(shouldRefresh, "source",
                       function() return reaper.GetMediaItemTake_Source(self.pointer) end)
end

function MediaTake:getFileName(shouldRefresh)
    return self:getter(shouldRefresh, "fileName",
                       function() return getTakeFileName(self) end)
end

function MediaTake:getSourceLength(shouldRefresh)
    return self:getter(shouldRefresh, "sourceLength",
                       function() return getTakeSourceLength(self) end)
end

function MediaTake:getPitchEnvelope(shouldRefresh)
    return self:getter(shouldRefresh, "pitchEnvelope",
                       function() return getTakePitchEnvelope(self) end)
end

function MediaTake:getPlayrate(shouldRefresh)
    return self:getter(shouldRefresh, "playrate",
                       function() return reaper.GetMediaItemTakeInfo_Value(self.pointer, "D_PLAYRATE") end)
end

function MediaTake:getStartOffset(shouldRefresh)
    return self:getter(shouldRefresh, "startOffset",
                       function() return self:getSourcePosition(0.0) end)
end

return MediaTake