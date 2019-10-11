package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Reaper = require "Pitch Correction.Reaper Functions"
local MediaItem = require "Pitch Correction.Media Item"
local ReaperPointerWrapper = require "Pitch Correction.Reaper Pointer Wrapper"

------------------ Track ------------------

local Track = setmetatable({}, { __index = ReaperPointerWrapper })
function Track:new(object)
    local object = object or {}
    setmetatable(object, { __index = self })
    object:init()
    return object
end

function Track:init()
    self.pointerType = "MediaTrack*"
    ReaperPointerWrapper.init(self)
end

------------------ Setters ------------------

function Track:addMediaItem()
    return MediaItem:new{ pointer = reaper.AddMediaItemToTrack(self.pointer) }
end

return Track