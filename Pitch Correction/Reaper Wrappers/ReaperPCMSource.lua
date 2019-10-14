package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "Pitch Correction.Reaper Wrappers.ReaperPointerWrapper"

local ReaperPCMSource = { pointerType = "PCM_source*" }
setmetatable(ReaperPCMSource, { __index = ReaperPointerWrapper })

ReaperPCMSource._members = {
    --{ key = "track",
    --    getter = function(self) return tbl.item.track end },
}

function ReaperPCMSource:new(object)
    local object = object or {}
    object._base = self
    setmetatable(object, object)
    ReaperPointerWrapper.init(object)
    return object
end

return ReaperPCMSource