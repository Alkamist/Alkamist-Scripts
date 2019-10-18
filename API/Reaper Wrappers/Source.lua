local PointerWrapper = require "API.Reaper Wrappers.PointerWrapper"

local function Source(project, pointer)
    if project == nil then return nil end
    if pointer == nil then return nil end

    local source = PointerWrapper(pointer, "PCM_source*")

    -- Private Members:

    local _project = project

    -- Getters:

    function source:getProject() return _project end
    function source:getFileName()
        local url = reaper.GetMediaSourceFileName(self:getPointer(), "")
        return url:match("[^/\\]+$")
    end
    function source:getLength()
        local _, _, sourceLength = reaper.PCM_Source_GetSectionInfo(self:getPointer())
        return sourceLength
    end

    -- Setters:

    return source
end

return Source