package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "API.Reaper Wrappers.ReaperPointerWrapper"

local ReaperPCMSource = { pointerType = "PCM_source*" }
setmetatable(ReaperPCMSource, { __index = ReaperPointerWrapper })

function ReaperPCMSource:new(object)
    local object = object or {}
    setmetatable(object, { __index = self })
    return object
end

function ReaperPCMSource:getFileName()
    local url = reaper.GetMediaSourceFileName(self.pointer, "")
    return url:match("[^/\\]+$")
end

function ReaperPCMSource:getLength()
    local _, _, sourceLength = reaper.PCM_Source_GetSectionInfo(self.pointer)
    return sourceLength
end

return ReaperPCMSource