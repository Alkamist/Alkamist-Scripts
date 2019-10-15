package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "API.Reaper Wrappers.ReaperPointerWrapper"

local ReaperItem = { pointerType = "MediaItem*" }
setmetatable(ReaperItem, { __index = ReaperPointerWrapper })

ReaperItem._members = {
    { key = "length",
        getter = function(self) return self:getLength() end,
        setter = function(self, value) self:setLength(value) end },

    { key = "leftEdge",
        getter = function(self) return self:getLeftEdge() end,
        setter = function(self, value) self:setLeftEdge(value) end },

    { key = "rightEdge",
        getter = function(self) return self:getRightEdge() end,
        setter = function(self, value) self:setRightEdge(value) end },

    { key = "loops",
        getter = function(self) return self:getLoops() end,
        setter = function(self, value) self:setLoops(value) end },

    { key = "activeTake",
        getter = function(self) return self:getActiveTake() end },

    { key = "track",
        getter = function(self) return self:getTrack() end },

    { key = "isEmpty",
        getter = function(self) return self:isTypeEmpty() end },

    { key = "name",
        getter = function(self) return self:getName() end },

    { key = "takes",
        getter = function(self) return self:getTakes() end },

    { key = "isSelected",
        getter = function(self) return self:getIsSelected() end,
        setter = function(self, value) self:setSelected(value) end },
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

function ReaperItem:getIsSelected()
    return reaper.IsMediaItemSelected(self.pointer)
end

function ReaperItem:setSelected(value)
    reaper.SetMediaItemSelected(self.pointer, value)
end

function ReaperItem:getLength()
    return reaper.GetMediaItemInfo_Value(self.pointer, "D_LENGTH")
end

function ReaperItem:setLength(value)
    reaper.SetMediaItemLength(self.pointer, value, false)
end

function ReaperItem:getLeftEdge()
    return reaper.GetMediaItemInfo_Value(self.pointer, "D_POSITION")
end

function ReaperItem:setLeftEdge(value)
    reaper.SetMediaItemPosition(self.pointer, value, false)
end

function ReaperItem:getRightEdge()
    return self:getLeftEdge() + self:getLength()
end

function ReaperItem:setRightEdge(value)
    self:setLeftEdge(math.max(0.0, value - self:getLength()))
end

function ReaperItem:getLoops()
    return reaper.GetMediaItemInfo_Value(self.pointer, "B_LOOPSRC") > 0
end

function ReaperItem:setLoops(value)
    reaper.SetMediaItemInfo_Value(self.pointer, "B_LOOPSRC", value and 1 or 0)
end

function ReaperItem:getActiveTake()
    return self.project:wrapTake(reaper.GetActiveTake(self.pointer))
end

function ReaperItem:getTrack()
    return self.project:wrapTrack(reaper.GetMediaItemTrack(self.pointer))
end

function ReaperItem:isTypeEmpty()
    return self:getActiveTake():getType() == nil
end

function ReaperItem:getName()
    if self.isEmpty then
        return reaper.ULT_GetMediaItemNote(self.pointer)
    end
    return self.activeTake.name
end

function ReaperItem:getTakeCount()
    return reaper.CountTakes(self.pointer)
end

function ReaperItem:getTake(takeNumber)
    return self.project:wrapTake(reaper.GetTake(self.pointer, takeNumber - 1))
end

function ReaperItem:getTakes()
    return ReaperPointerWrapper.getIterator(self, self.getTake, self.getTakeCount)
end

return ReaperItem