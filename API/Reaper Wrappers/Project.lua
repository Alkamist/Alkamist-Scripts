local PointerWrapper = require "API.Reaper Wrappers.PointerWrapper"
local Track =          require "API.Reaper Wrappers.Track"
local Envelope =       require "API.Reaper Wrappers.Envelope"
local Item =           require "API.Reaper Wrappers.Item"
local Take =           require "API.Reaper Wrappers.Take"
local Source =         require "API.Reaper Wrappers.Source"

local Project = setmetatable({}, { __index = PointerWrapper })

function Project:new(pointer)
    if pointer == nil then return nil end

    local instance = PointerWrapper:new(pointer, "ReaProject*")
    instance._wrappers = {}

    return setmetatable(instance, { __index = self })
end

-- Getters:

function Project:wrapPointer(pointer, wrapperType)
    local pointerString = tostring(pointer)
    self._wrappers[pointerString] = self._wrappers[pointerString] or wrapperType:new(self, pointer)
    return self._wrappers[pointerString]
end
function Project:wrapTrack(pointer)            return self:wrapPointer(pointer, Track) end
function Project:wrapEnvelope(pointer)         return self:wrapPointer(pointer, Envelope) end
function Project:wrapItem(pointer)             return self:wrapPointer(pointer, Item) end
function Project:wrapTake(pointer)             return self:wrapPointer(pointer, Take) end
function Project:wrapSource(pointer)           return self:wrapPointer(pointer, Source) end

function Project:validateChild(child)          return child:validatePointer(self:getPointer()) end
function Project:getName()                     return reaper.GetProjectName(self:getPointer(), "") end
function Project:getItemCount()                return reaper.CountMediaItems(self:getPointer()) end
function Project:getSelectedItemCount()        return reaper.CountSelectedMediaItems(self:getPointer()) end
function Project:getTrackCount()               return reaper.CountTracks(self:getPointer()) end
function Project:getSelectedTrackCount()       return reaper.CountSelectedTracks(self:getPointer()) end
function Project:getItem(itemNumber)           return self:wrapItem(reaper.GetMediaItem(self:getPointer(), itemNumber - 1)) end
function Project:getSelectedItem(itemNumber)   return self:wrapItem(reaper.GetSelectedMediaItem(self:getPointer(), itemNumber - 1)) end
function Project:getTrack(trackNumber)         return self:wrapTrack(reaper.GetTrack(self:getPointer(), trackNumber - 1)) end
function Project:getSelectedTrack(trackNumber) return self:wrapTrack(reaper.GetSelectedTrack(self:getPointer(), trackNumber - 1)) end
function Project:getItems()                    return self:getIterator(self, self.getItem, self.getItemCount) end
function Project:getSelectedItems()            return self:getIterator(self, self.getSelectedItem, self.getSelectedItemCount) end
function Project:getTracks()                   return self:getIterator(self, self.getTrack, self.getTrackCount) end
function Project:getSelectedTracks()           return self:getIterator(self, self.getSelectedTrack, self.getSelectedTrackCount) end
function Project:getEditCursorTime()           return reaper.GetCursorPositionEx(self:getPointer()) end
function Project:getPlayCursorTime()           return reaper.GetPlayPositionEx(self:getPointer()) end
function Project:isPlaying()                   return reaper.GetPlayStateEx(self:getPointer()) & 1 == 1 end
function Project:isPaused()                    return reaper.GetPlayStateEx(self:getPointer()) & 2 == 2 end
function Project:isRecording()                 return reaper.GetPlayStateEx(self:getPointer()) & 4 == 4 end
function Project:getIterator(child, getterFn, countFn)
    return setmetatable({}, {
        __index = function(tbl, index)
            return getterFn(child, index)
        end,
        __len = function(tbl)
            if countFn then return countFn(child) end
        end
    })
end

-- Setters:

function Project:setEditCursorTime(time, moveView, seekPlay) reaper.SetEditCurPos2(self:getPointer(), time, moveView or false, seekPlay or true) end
function Project:mainCommand(id, flag)
    local flag = flag or 0
    local id = id
    if type(id) == "string" then id = reaper.NamedCommandLookup(id) end
    reaper.Main_OnCommandEx(id, flag, self:getPointer())
end

return Project