package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "API.Reaper Wrappers.ReaperPointerWrapper"

local ReaperEnvelope = { pointerType = "TrackEnvelope*" }
setmetatable(ReaperEnvelope, { __index = ReaperPointerWrapper })

function ReaperEnvelope:new(object)
    local object = object or {}
    setmetatable(object, { __index = self })
    return object
end

function ReaperEnvelope:getTrack()
    local parentTrack, _, _ = reaper.Envelope_GetParentTrack(self.pointer)
    return self.project:wrapTrack(parentTrack)
end

function ReaperEnvelope:getName()
    local _, name = reaper.GetEnvelopeName(self.pointer)
    return name
end

function ReaperEnvelope:getStateChunk()
    local _, stateChunk = reaper.GetEnvelopeStateChunk(self.pointer, "", true)
    return stateChunk
end

function ReaperEnvelope:setStateChunk(chunk)
    reaper.SetEnvelopeStateChunk(self.pointer, chunk, true)
end

function ReaperEnvelope:show()
    if not self:isVisible() then
        self:setStateChunk(string.gsub(self:getStateChunk(), "VIS %d", "VIS 1"))
    end
end

function ReaperEnvelope:hide()
    if self:isVisible() then
        self:setStateChunk(string.gsub(self:getStateChunk(), "VIS %d", "VIS 0"))
    end
end

function ReaperEnvelope:isVisible()
    return tonumber(self.stateChunk:match("VIS (%d)")) > 0
end

function ReaperEnvelope:setVisibility(visibility)
    if visibility then self:show() else self:hide() end
end

function ReaperEnvelope:getTake()
    local take, _, _ = reaper.Envelope_GetParentTake(self.pointer)
    return self.project:wrapTake(take)
end

function ReaperEnvelope:getFXNumber()
    local _, fxIndex, _ = reaper.Envelope_GetParentTake(self.pointer)
    return fxIndex + 1
end

function ReaperEnvelope:getParameterNumber()
    local _, _, parameterIndex = reaper.Envelope_GetParentTake(self.pointer)
    return parameterIndex + 1
end

return ReaperEnvelope