package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "API.Reaper Wrappers.ReaperPointerWrapper"

local ReaperItem = { pointerType = "MediaItem*" }
setmetatable(ReaperItem, { __index = ReaperPointerWrapper })

ReaperItem._members = {
    { key = "length",
        getter = function(self) return reaper.GetMediaItemInfo_Value(self.pointer, "D_LENGTH") end,
        setter = function(self, value) reaper.SetMediaItemLength(self.pointer, value, false) end },

    { key = "leftEdge",
        getter = function(self) return reaper.GetMediaItemInfo_Value(self.pointer, "D_POSITION") end,
        setter = function(self, value) reaper.SetMediaItemPosition(self.pointer, value, false) end },

    { key = "rightEdge",
        getter = function(self) return self.leftEdge + self.length end,
        setter = function(self, value) self.leftEdge = math.max(0.0, value - self.length) end },

    { key = "loops",
        getter = function(self) return reaper.GetMediaItemInfo_Value(self.pointer, "B_LOOPSRC") > 0 end,
        setter = function(self, value) reaper.SetMediaItemInfo_Value(self.pointer, "B_LOOPSRC", value and 1 or 0) end },

    { key = "activeTake",
        getter = function(self) return self.factory.createNew(reaper.GetActiveTake(self.pointer)) end },

    { key = "track",
        getter = function(self) return self.factory.createNew(reaper.GetMediaItemTrack(self.pointer)) end },

    { key = "isEmpty",
        getter = function(self) return self.activeTake.type == nil end },

    { key = "name",
        getter = function(self) return self:getName() end },
}

function ReaperItem:new(object)
    local object = object or {}
    object._base = self
    setmetatable(object, object)
    ReaperPointerWrapper.init(object)
    return object
end

--------------------- Unique Functions  ---------------------


--------------------- Member Helper Functions  ---------------------

function ReaperItem:getName()
    if self.isEmpty then
        return reaper.ULT_GetMediaItemNote(self.pointer)
    end
    return self.activeTake.name
end

return ReaperItem