local reaper = reaper

local PointerWrapper = require "API.Reaper Wrappers.PointerWrapper"
local Track =          require "API.Reaper Wrappers.Track"
local Envelope =       require "API.Reaper Wrappers.Envelope"
local Item =           require "API.Reaper Wrappers.Item"
local Take =           require "API.Reaper Wrappers.Take"
local Source =         require "API.Reaper Wrappers.Source"

local Project = setmetatable({}, { __index = PointerWrapper })

function Project:new(pointer)
    if pointer == nil then return nil end

    local base = PointerWrapper:new(pointer, "ReaProject*")
    local self = setmetatable(base, { __index = self })
    self.wrappers = {}

    return self
end

-- Getters:

function Project:wrapPointer(pointer, wrapperType)
    local pointerString = tostring(pointer)
    self.wrappers[pointerString] = self.wrappers[pointerString] or wrapperType:new(self, pointer)
    return self.wrappers[pointerString]
end
function Project:wrapTrack(pointer)            return self:wrapPointer(pointer, Track) end
function Project:wrapEnvelope(pointer)         return self:wrapPointer(pointer, Envelope) end
function Project:wrapItem(pointer)             return self:wrapPointer(pointer, Item) end
function Project:wrapTake(pointer)             return self:wrapPointer(pointer, Take) end
function Project:wrapSource(pointer)           return self:wrapPointer(pointer, Source) end

function Project:validateChild(child)          return child:validatePointer(self.pointer) end
function Project:getName()                     return reaper.GetProjectName(self.pointer, "") end
function Project:getItemCount()                return reaper.CountMediaItems(self.pointer) end
function Project:getSelectedItemCount()        return reaper.CountSelectedMediaItems(self.pointer) end
function Project:getTrackCount()               return reaper.CountTracks(self.pointer) end
function Project:getSelectedTrackCount()       return reaper.CountSelectedTracks(self.pointer) end
function Project:getItem(itemNumber)           return self:wrapItem(reaper.GetMediaItem(self.pointer, itemNumber - 1)) end
function Project:getSelectedItem(itemNumber)   return self:wrapItem(reaper.GetSelectedMediaItem(self.pointer, itemNumber - 1)) end
function Project:getTrack(trackNumber)         return self:wrapTrack(reaper.GetTrack(self.pointer, trackNumber - 1)) end
function Project:getSelectedTrack(trackNumber) return self:wrapTrack(reaper.GetSelectedTrack(self.pointer, trackNumber - 1)) end
function Project:getItems()                    return self:getIterator(self.getItem, self.getItemCount) end
function Project:getSelectedItems()            return self:getIterator(self.getSelectedItem, self.getSelectedItemCount) end
function Project:getTracks()                   return self:getIterator(self.getTrack, self.getTrackCount) end
function Project:getSelectedTracks()           return self:getIterator(self.getSelectedTrack, self.getSelectedTrackCount) end
function Project:getEditCursorTime()           return reaper.GetCursorPositionEx(self.pointer) end
function Project:getPlayCursorTime()           return reaper.GetPlayPositionEx(self.pointer) end
function Project:isPlaying()                   return reaper.GetPlayStateEx(self.pointer) & 1 == 1 end
function Project:isPaused()                    return reaper.GetPlayStateEx(self.pointer) & 2 == 2 end
function Project:isRecording()                 return reaper.GetPlayStateEx(self.pointer) & 4 == 4 end

-- Setters:

function Project:setEditCursorTime(time, moveView, seekPlay) reaper.SetEditCurPos2(self.pointer, time, moveView or false, seekPlay or true) end
function Project:mainCommand(id, flag)
    local flag = flag or 0
    local id = id
    if type(id) == "string" then id = reaper.NamedCommandLookup(id) end
    reaper.Main_OnCommandEx(id, flag, self.pointer)
end

return Project