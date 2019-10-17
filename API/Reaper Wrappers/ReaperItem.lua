package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "API.Reaper Wrappers.ReaperPointerWrapper"

local ReaperItem = { pointerType = "MediaItem*" }
setmetatable(ReaperItem, { __index = ReaperPointerWrapper })

function ReaperItem:new(object)
    local object = object or {}
    setmetatable(object, { __index = self })
    return object
end

function ReaperItem:isSelected()
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

function ReaperItem:isEmpty()
    return self:getActiveTake():getType() == nil
end

function ReaperItem:getName()
    if self:isEmpty() then
        return reaper.ULT_GetMediaItemNote(self.pointer)
    end
    return self:getActiveTake():getName()
end

function ReaperItem:getTakeCount()
    return reaper.CountTakes(self.pointer)
end

function ReaperItem:getTake(takeNumber)
    return self.project:wrapTake(reaper.GetTake(self.pointer, takeNumber - 1))
end

function ReaperItem:getTakes()
    return self:getIterator(self.getTake, self.getTakeCount)
end

return ReaperItem