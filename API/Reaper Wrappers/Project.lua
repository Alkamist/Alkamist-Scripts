local PointerWrapper = require "API.Reaper Wrappers.PointerWrapper"
local Track =          require "API.Reaper Wrappers.Track"
local Envelope =       require "API.Reaper Wrappers.Envelope"
local Item =           require "API.Reaper Wrappers.Item"
local Take =           require "API.Reaper Wrappers.Take"
local Source =         require "API.Reaper Wrappers.Source"

local function Project(pointer)
    if pointer == nil then return nil end

    local project = PointerWrapper(pointer, "ReaProject*")

    -- Getters:

    function project:wrapTrack(pointer)            return Track(self, pointer) end
    function project:wrapEnvelope(pointer)         return Envelope(self, pointer) end
    function project:wrapItem(pointer)             return Item(self, pointer) end
    function project:wrapTake(pointer)             return Take(self, pointer) end
    function project:wrapSource(pointer)           return Source(self, pointer) end

    function project:validateChild(child)          return child:validatePointer(self:getPointer()) end
    function project:getName()                     return reaper.GetProjectName(self:getPointer(), "") end
    function project:getItemCount()                return reaper.CountMediaItems(self:getPointer()) end
    function project:getSelectedItemCount()        return reaper.CountSelectedMediaItems(self:getPointer()) end
    function project:getTrackCount()               return reaper.CountTracks(self:getPointer()) end
    function project:getSelectedTrackCount()       return reaper.CountSelectedTracks(self:getPointer()) end
    function project:getItem(itemNumber)           return self:wrapItem(reaper.GetMediaItem(self:getPointer(), itemNumber - 1)) end
    function project:getSelectedItem(itemNumber)   return self:wrapItem(reaper.GetSelectedMediaItem(self:getPointer(), itemNumber - 1)) end
    function project:getTrack(trackNumber)         return self:wrapTrack(reaper.GetTrack(self:getPointer(), trackNumber - 1)) end
    function project:getSelectedTrack(trackNumber) return self:wrapTrack(reaper.GetSelectedTrack(self:getPointer(), trackNumber - 1)) end
    function project:getItems()                    return self:getIterator(self, self.getItem, self.getItemCount) end
    function project:getSelectedItems()            return self:getIterator(self, self.getSelectedItem, self.getSelectedItemCount) end
    function project:getTracks()                   return self:getIterator(self, self.getTrack, self.getTrackCount) end
    function project:getSelectedTracks()           return self:getIterator(self, self.getSelectedTrack, self.getSelectedTrackCount) end
    function project:getEditCursorTime()           return reaper.GetCursorPositionEx(self:getPointer()) end
    function project:getPlayCursorTime()           return reaper.GetPlayPositionEx(self:getPointer()) end
    function project:isPlaying()                   return reaper.GetPlayStateEx(self:getPointer()) & 1 == 1 end
    function project:isPaused()                    return reaper.GetPlayStateEx(self:getPointer()) & 2 == 2 end
    function project:isRecording()                 return reaper.GetPlayStateEx(self:getPointer()) & 4 == 4 end
    function project:getIterator(self, getterFn, countFn)
        return setmetatable({}, {
            __index = function(tbl, index)
                return getterFn(self, index)
            end,
            __len = function(tbl)
                if countFn then return countFn(self) end
            end
        })
    end

    -- Setters:

    function project:setEditCursorTime(time, moveView, seekPlay) reaper.SetEditCurPos2(self:getPointer(), time, moveView or false, seekPlay or true) end
    function project:mainCommand(id, flag)
        local flag = flag or 0
        local id = id
        if type(id) == "string" then id = reaper.NamedCommandLookup(id) end
        reaper.Main_OnCommandEx(id, flag, self:getPointer())
    end

    return project
end

return Project