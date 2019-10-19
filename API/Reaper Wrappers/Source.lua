local PointerWrapper = require "API.Reaper Wrappers.PointerWrapper"

local Source = setmetatable({}, { __index = PointerWrapper })

function Source:new(project, pointer)
    if project == nil then return nil end
    if pointer == nil then return nil end

    local instance = PointerWrapper:new(pointer, "PCM_source*")
    instance._project = project

    return setmetatable(instance, { __index = self })
end

function Source:getProject() return self._project end
function Source:getFileName()
    local url = reaper.GetMediaSourceFileName(self:getPointer(), "")
    return url:match("[^/\\]+$")
end
function Source:getLength()
    local _, _, sourceLength = reaper.PCM_Source_GetSectionInfo(self:getPointer())
    return sourceLength
end

return Source