local reaper = reaper

local PointerWrapper = require "API.Reaper Wrappers.PointerWrapper"

local Envelope = setmetatable({}, { __index = PointerWrapper })

function Envelope:new(project, pointer)
    if project == nil then return nil end
    if pointer == nil then return nil end

    local base = PointerWrapper:new(pointer, "TrackEnvelope*")
    local self = setmetatable(base, { __index = self })
    self.project = project

    return self
end

-- Getters:

function Envelope:getProject() return self.project end
function Envelope:getTrack()
    local parentTrack = reaper.Envelope_GetParentTrack(self.pointer)
    return self:getProject():wrapTrack(parentTrack)
end
function Envelope:getName()
    local _, name = reaper.GetEnvelopeName(self.pointer)
    return name
end
function Envelope:getStateChunk()
    local _, stateChunk = reaper.GetEnvelopeStateChunk(self.pointer, "", true)
    return stateChunk
end
function Envelope:isVisible() return tonumber(self:getStateChunk():match("VIS (%d)")) > 0 end
function Envelope:getTake()
    local take = reaper.Envelope_GetParentTake(self.pointer)
    return self:getProject():wrapTake(take)
end
function Envelope:getFXNumber()
    local _, fxIndex = reaper.Envelope_GetParentTake(self.pointer)
    return fxIndex + 1
end
function Envelope:getParameterNumber()
    local _, _, parameterIndex = reaper.Envelope_GetParentTake(self.pointer)
    return parameterIndex + 1
end

-- Setters:

function Envelope:setStateChunk(chunk) reaper.SetEnvelopeStateChunk(self.pointer, chunk, true) end
function Envelope:show()
    if not self:isVisible() then
        self:setStateChunk(string.gsub(self:getStateChunk(), "VIS %d", "VIS 1"))
    end
end
function Envelope:hide()
    if self:isVisible() then
        self:setStateChunk(string.gsub(self:getStateChunk(), "VIS %d", "VIS 0"))
    end
end
function Envelope:setVisibility(visibility) if visibility then self:show() else self:hide() end end

return Envelope