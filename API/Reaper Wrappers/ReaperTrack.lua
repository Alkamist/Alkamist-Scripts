package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "API.Reaper Wrappers.ReaperPointerWrapper"

local ReaperTrack = { pointerType = "MediaTrack*" }
setmetatable(ReaperTrack, { __index = ReaperPointerWrapper })

ReaperTrack._members = {
    { key = "number",
        getter = function(self) return reaper.GetMediaTrackInfo_Value(self.pointer, "IP_TRACKNUMBER") end },
}

function ReaperTrack:new(object)
    local object = object or {}
    object._base = self
    setmetatable(object, object)
    ReaperPointerWrapper.init(object)
    return object
end

--------------------- Unique Functions  ---------------------


--------------------- Member Helper Functions  ---------------------

return ReaperTrack