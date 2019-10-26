local reaper = reaper

local PointerWrapper = require "API.Reaper Wrappers.PointerWrapper"

local Source = setmetatable({}, { __index = PointerWrapper })

function Source:new(project, pointer)
    if project == nil then return nil end
    if pointer == nil then return nil end

    local base = PointerWrapper:new(pointer, "PCM_source*")
    local self = setmetatable(base, { __index = self })
    self.project = project

    return self
end

function Source:getProject() return self.project end
function Source:getFileName()
    local url = reaper.GetMediaSourceFileName(self.pointer, "")
    return url:match("[^/\\]+$")
end
function Source:getLength()
    local _, _, sourceLength = reaper.PCM_Source_GetSectionInfo(self.pointer)
    return sourceLength
end

return Source