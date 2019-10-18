local PointerWrapper = require "API.Reaper Wrappers.PointerWrapper"

local function Envelope(project, pointer)
    if project == nil then return nil end
    if pointer == nil then return nil end

    local envelope = PointerWrapper(pointer, "TrackEnvelope*")

    -- Private Members:

    local _project = project

    -- Getters:

    function envelope:getProject() return _project end
    function envelope:getTrack()
        local parentTrack = reaper.Envelope_GetParentTrack(self:getPointer())
        return self:getProject():wrapTrack(parentTrack)
    end
    function envelope:getName()
        local _, name = reaper.GetEnvelopeName(self:getPointer())
        return name
    end
    function envelope:getStateChunk()
        local _, stateChunk = reaper.GetEnvelopeStateChunk(self:getPointer(), "", true)
        return stateChunk
    end
    function envelope:isVisible() return tonumber(self:getStateChunk():match("VIS (%d)")) > 0 end
    function envelope:getTake()
        local take = reaper.Envelope_GetParentTake(self:getPointer())
        return self:getProject():wrapTake(take)
    end
    function envelope:getFXNumber()
        local _, fxIndex = reaper.Envelope_GetParentTake(self:getPointer())
        return fxIndex + 1
    end
    function envelope:getParameterNumber()
        local _, _, parameterIndex = reaper.Envelope_GetParentTake(self:getPointer())
        return parameterIndex + 1
    end

    -- Setters:

    function envelope:setStateChunk(chunk) reaper.SetEnvelopeStateChunk(self:getPointer(), chunk, true) end
    function envelope:show()
        if not self:isVisible() then
            self:setStateChunk(string.gsub(self:getStateChunk(), "VIS %d", "VIS 1"))
        end
    end
    function envelope:hide()
        if self:isVisible() then
            self:setStateChunk(string.gsub(self:getStateChunk(), "VIS %d", "VIS 0"))
        end
    end
    function envelope:setVisibility(visibility) if visibility then self:show() else self:hide() end end

    return envelope
end

return Envelope