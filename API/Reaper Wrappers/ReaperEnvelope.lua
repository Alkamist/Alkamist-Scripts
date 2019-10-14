package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "API.Reaper Wrappers.ReaperPointerWrapper"

local ReaperEnvelope = { pointerType = "TrackEnvelope*" }
setmetatable(ReaperEnvelope, { __index = ReaperPointerWrapper })

ReaperEnvelope._members = {
    { key = "name",
        getter = function(self) return self:getName() end },

    { key = "track",
        getter = function(self) return self:getTrack() end },

    { key = "take",
        getter = function(self) return self:getTake() end },

    { key = "fxNumber",
        getter = function(self) return self:getFXNumber() end },

    { key = "parameterNumber",
        getter = function(self) return self:getParameterNumber() end },

    { key = "isVisible",
        getter = function(self) return self:getVisibility() end,
        setter = function(self, value) self:setVisibility(value) end },

    { key = "stateChunk",
        getter = function(self) return self:getStateChunk() end,
        setter = function(self, value) self:setStateChunk(value) end },
}

function ReaperEnvelope:new(object)
    local object = object or {}
    object._base = self
    setmetatable(object, object)
    ReaperPointerWrapper.init(object)
    return object
end

--------------------- Unique Functions  ---------------------


--------------------- Member Helper Functions  ---------------------

function ReaperEnvelope:getTrack()
    local parentTrack, _, _ = reaper.Envelope_GetParentTrack(self.pointer)
    return self.factory.createNew(parentTrack, self.project)
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
    if not self.isVisible then
        self:setStateChunk(string.gsub(self:getStateChunk(), "VIS %d", "VIS 1"))
    end
end

function ReaperEnvelope:hide()
    if self.isVisible then
        self:setStateChunk(string.gsub(self:getStateChunk(), "VIS %d", "VIS 0"))
    end
end

function ReaperEnvelope:getVisibility()
    return tonumber(self.stateChunk:match("VIS (%d)")) > 0
end

function ReaperEnvelope:setVisibility(visibility)
    if visibility then self:show() else self:hide() end
end

function ReaperEnvelope:getTake()
    local take, _, _ = reaper.Envelope_GetParentTake(self.pointer)
    return self.factory.createNew(take, self.project)
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