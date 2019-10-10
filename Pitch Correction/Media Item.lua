package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "Pitch Correction.Reaper Pointer Wrapper"
local MediaTake = require "Pitch Correction.Media Take"

------------------ Media Item ------------------

local MediaItem = setmetatable({}, { __index = ReaperPointerWrapper })
function MediaItem:new(object)
    local object = object or {}
    setmetatable(object, { __index = self })
    object:init()
    return object
end

function MediaItem:newFromSelectedIndex(index)
    local numSelectedItems = reaper.CountSelectedMediaItems(0)
    if index <= numSelectedItems then
        return self:new({ item = reaper.GetSelectedMediaItem(0, index - 1) })
    end
    return nil
end

function MediaItem:init()
    self.pointer = self.item
    self.pointerType = "MediaItem*"
    ReaperPointerWrapper.init(self)
end

function MediaItem:getActiveTake(shouldRefresh)
    return self:getter(shouldRefresh, "activeTake",
                       function()
                           return MediaTake:new( {
                               take = reaper.GetActiveTake(self.pointer),
                               item = self
                            } )
                       end)
end

function MediaItem:getTrack(shouldRefresh)
    return self:getter(shouldRefresh, "track",
                       function() return reaper.GetMediaItem_Track(self.pointer) end)
end

function MediaItem:getLength(shouldRefresh)
    return self:getter(shouldRefresh, "length",
                       function() return reaper.GetMediaItemInfo_Value(self.pointer, "D_LENGTH") end)
end

function MediaItem:getLeftTime(shouldRefresh)
    return self:getter(shouldRefresh, "leftTime",
                       function() return reaper.GetMediaItemInfo_Value(self.pointer, "D_POSITION") end)
end

function MediaItem:getRightTime(shouldRefresh)
    return self:getter(shouldRefresh, "rightTime",
                       function() return self:getLeftTime() + self:getLength() end)
end

function MediaItem:isEmpty(shouldRefresh)
    return self:getter(shouldRefresh, "isEmptyType",
                       function() return self:getActiveTake():getType() == nil end)
end

function MediaItem:getName(shouldRefresh)
    return self:getter(shouldRefresh, "name",
                       function()
                           if self:getActiveTake():getType() == nil then
                               return reaper.ULT_GetMediaItemNote(self.pointer)
                           end
                           return self:getActiveTake():getName()
                       end)
end

return MediaItem