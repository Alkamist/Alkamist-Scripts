package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Reaper = require "Pitch Correction.Reaper Functions"
local ReaperPointerWrapper = require "Pitch Correction.Reaper Pointer Wrapper"

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
    local tempMarkerIndex = reaper.SetTakeStretchMarker(self.pointer, -1, time * self:getPlayrate())
    local _, pos, srcPos = reaper.GetTakeStretchMarker(self.pointer, tempMarkerIndex)
    reaper.DeleteTakeStretchMarkers(self.pointer, tempMarkerIndex)
    return srcPos
end

function MediaTake:getItem(shouldRefresh)
    return self:getter(shouldRefresh, "item",
                       function() return reaper.GetMediaItemTake_Item(self.pointer) end)
end

function MediaTake:getType(shouldRefresh)
    return self:getter(shouldRefresh, "type",
                       function()
                           if reaper.TakeIsMIDI(self.pointer) then
                               return "midi"
                           end

                           return "audio"
                       end)
end

function MediaTake:getName(shouldRefresh)
    return self:getter(shouldRefresh, "name",
                       function() return reaper.GetTakeName(self.pointer) end)
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
                       function()
                           local url = reaper.GetMediaSourceFileName(self:getSource(), "")
                           return url:match("[^/\\]+$")
                       end)
end

function MediaTake:getSourceLength(shouldRefresh)
    return self:getter(shouldRefresh, "sourceLength",
                       function()
                           local _, _, takeSourceLength = reaper.PCM_Source_GetSectionInfo(self:getSource())
                           return takeSourceLength
                       end)
end

function MediaTake:getPitchEnvelope(shouldRefresh)
    return self:getter(shouldRefresh, "pitchEnvelope",
                       function()
                           local pitchEnvelope = reaper.GetTakeEnvelopeByName(self.pointer, "Pitch")

                           if not pitchEnvelope or not reaper.ValidatePtr2(0, pitchEnvelope, "TrackEnvelope*") then
                               Reaper.mainCommand("_S&M_TAKEENV10") -- Show and unbypass take pitch envelope
                               pitchEnvelope = reaper.GetTakeEnvelopeByName(self.pointer, "Pitch")
                           end

                           Reaper.mainCommand("_S&M_TAKEENVSHOW8") -- Hide take pitch envelope

                           return pitchEnvelope
                       end)
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