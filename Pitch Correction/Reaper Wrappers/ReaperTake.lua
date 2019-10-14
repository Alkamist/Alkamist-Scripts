package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "Pitch Correction.Reaper Wrappers.ReaperPointerWrapper"

local ReaperTake = { pointerType = "MediaItem_Take*" }
setmetatable(ReaperTake, { __index = ReaperPointerWrapper })

ReaperTake._members = {
    { key = "track",
        getter = function(self) return tbl.item.track end },

    { key = "name",
        getter = function(self) return reaper.GetTakeName(tbl.pointer) end,
        setter = function(self, value) reaper.GetSetMediaItemTakeInfo_String(tbl.pointer, "P_NAME", "", true) end },

    { key = "GUID",
        getter = function(self) return reaper.BR_GetMediaItemTakeGUID(tbl.pointer) end },

    { key = "item",
        getter = function(self) return tbl.factory.createNew(reaper.GetMediaItemTake_Item(tbl.pointer)) end },
}

function ReaperTake:new(object)
    local object = object or {}
    object._base = self
    setmetatable(object, object)
    ReaperPointerWrapper.init(object)
    return object
end

function ReaperTake:getType()
    if reaper.TakeIsMIDI(self.pointer) then
        return "midi"
    end
    return "audio"
end

return ReaperTake