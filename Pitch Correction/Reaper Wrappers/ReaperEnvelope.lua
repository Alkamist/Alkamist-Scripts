package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "Pitch Correction.Reaper Wrappers.ReaperPointerWrapper"

local ReaperEnvelope = { pointerType = "TrackEnvelope*" }
setmetatable(ReaperEnvelope, { __index = ReaperPointerWrapper })

ReaperEnvelope._members = {
    { key = "track",
        getter = function(self) return tbl.factory.createNew(tbl:getTrack()) end },
}

function ReaperEnvelope:new(object)
    local object = object or {}
    object._base = self
    setmetatable(object, object)
    ReaperPointerWrapper.init(object)
    return object
end

function ReaperEnvelope:getTrack()
    local parentTrack, _, _ = reaper.Envelope_GetParentTrack(self.pointer)
    return parentTrack
end

return ReaperEnvelope