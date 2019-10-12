package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Track = require "Pitch Correction.Track"
local MediaTake = require "Pitch Correction.Media Take"
local ReaperPointerWrapper = require "Pitch Correction.Reaper Pointer Wrapper"

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
        return self:new{ pointer = reaper.GetSelectedMediaItem(0, index - 1) }
    end
    return nil
end

function MediaItem:init()
    self.pointerType = "MediaItem*"
    ReaperPointerWrapper.init(self)
end

------------------ Getters ------------------

function MediaItem:getActiveTake(refresh)
    return self:getter(refresh, "activeTake",
                       function()
                           return MediaTake:new{
                               pointer = reaper.GetActiveTake(self.pointer),
                               item = self
                            }
                       end)
end

function MediaItem:getTrack(refresh)
    return self:getter(refresh, "track",
                       function() return Track:new{ pointer = reaper.GetMediaItem_Track(self.pointer) } end)
end

function MediaItem:getLength(refresh)
    return self:getter(refresh, "length",
                       function() return reaper.GetMediaItemInfo_Value(self.pointer, "D_LENGTH") end)
end

function MediaItem:getLeftTime(refresh)
    return self:getter(refresh, "leftTime",
                       function() return reaper.GetMediaItemInfo_Value(self.pointer, "D_POSITION") end)
end

function MediaItem:getRightTime(refresh)
    return self:getter(refresh, "rightTime",
                       function() return self:getLeftTime() + self:getLength() end)
end

function MediaItem:isEmpty(refresh)
    return self:getter(refresh, "isEmptyType",
                       function() return self:getActiveTake():getType() == nil end)
end

function MediaItem:getName(refresh)
    return self:getter(refresh, "name",
                       function()
                           if self:getActiveTake():getType() == nil then
                               return reaper.ULT_GetMediaItemNote(self.pointer)
                           end
                           return self:getActiveTake():getName()
                       end)
end

------------------ Setters ------------------

function MediaItem:setLength(length)
    reaper.SetMediaItemInfo_Value(self.pointer, "D_LENGTH", length)
end

function MediaItem:setShouldLoop(shouldLoop)
    reaper.SetMediaItemInfo_Value(self.pointer, "B_LOOPSRC", tonumber(shouldLoop))
end

function MediaItem:addTake()
    return MediaTake:new{ pointer = reaper.AddTakeToMediaItem(self.pointer) }
end

return MediaItem