local Track =    require "API.Reaper Wrappers.Track"
local Envelope = require "API.Reaper Wrappers.Envelope"
local Item =     require "API.Reaper Wrappers.Item"
local Take =     require "API.Reaper Wrappers.Take"
local Source =   require "API.Reaper Wrappers.Source"

local function Project(pointer)
    if pointer == nil then return nil end
    local project = {}

    -- Private Members:

    local _pointer = pointer
    local _pointerType = "ReaProject*"

    -- Getters:

    function project:pointerIsValid()                      return reaper.ValidatePtr(_pointer, pointerType) end
    function project:validatePointer(pointer, pointerType) return reaper.ValidatePtr2(_pointer, pointer, pointerType) end
    function project:getName()                             return reaper.GetProjectName(_pointer, "") end
    function project:getItemCount()                        return reaper.CountMediaItems(_pointer) end
    function project:getSelectedItemCount()                return reaper.CountSelectedMediaItems(_pointer) end
    function project:getTrackCount()                       return reaper.CountTracks(_pointer) end
    function project:getSelectedTrackCount()               return reaper.CountSelectedTracks(_pointer) end
    function project:getItem(itemNumber)                   return Item(self, reaper.GetMediaItem(_pointer, itemNumber - 1)) end
    function project:getSelectedItem(itemNumber)           return Item(self, reaper.GetSelectedMediaItem(_pointer, itemNumber - 1)) end
    function project:getTrack(trackNumber)                 return Track(self, reaper.GetTrack(_pointer, trackNumber - 1)) end
    function project:getSelectedTrack(trackNumber)         return Track(self, reaper.GetSelectedTrack(_pointer, trackNumber - 1)) end
    function project:getItems()                            return self:getIterator(self.getItem, self.getItemCount) end
    function project:getSelectedItems()                    return self:getIterator(self.getSelectedItem, self.getSelectedItemCount) end
    function project:getTracks()                           return self:getIterator(self.getTrack, self.getTrackCount) end
    function project:getSelectedTracks()                   return self:getIterator(self.getSelectedTrack, self.getSelectedTrackCount) end
    function project:getEditCursorTime()                   return reaper.GetCursorPositionEx(_pointer) end
    function project:getPlayCursorTime()                   return reaper.GetPlayPositionEx(_pointer) end
    function project:isPlaying()                           return reaper.GetPlayStateEx(_pointer) & 1 == 1 end
    function project:isPaused()                            return reaper.GetPlayStateEx(_pointer) & 2 == 2 end
    function project:isRecording()                         return reaper.GetPlayStateEx(_pointer) & 4 == 4 end
    function project:getIterator(getterFn, countFn)
        return setmetatable({}, {
            __index = function(tbl, index)
                return getterFn(tbl, index)
            end,
            __len = function(tbl)
                if countFn then return countFn(tbl) end
                return rawlen(tbl)
            end
        })
    end

    -- Setters:

    function project:setEditCursorTime(time, moveView, seekPlay) reaper.SetEditCurPos2(_pointer, time, moveView or false, seekPlay or true) end
    function project:mainCommand(id, flag)
        local flag = flag or 0
        local id = id
        if type(id) == "string" then id = reaper.NamedCommandLookup(id) end
        reaper.Main_OnCommandEx(id, flag, _pointer)
    end

    return project
end

return Project