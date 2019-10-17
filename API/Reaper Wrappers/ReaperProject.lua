package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "API.Reaper Wrappers.ReaperPointerWrapper"
local ReaperTrack = require "API.Reaper Wrappers.ReaperTrack"
local ReaperEnvelope = require "API.Reaper Wrappers.ReaperEnvelope"
local ReaperItem = require "API.Reaper Wrappers.ReaperItem"
local ReaperTake = require "API.Reaper Wrappers.ReaperTake"
local ReaperPCMSource = require "API.Reaper Wrappers.ReaperPCMSource"

local ReaperProject = { pointerType = "ReaProject*" }
setmetatable(ReaperProject, { __index = ReaperPointerWrapper })

function ReaperProject:new(object)
    local object = object or {}
    setmetatable(object, { __index = self })
    return object
end

function ReaperProject:mainCommand(id, flag)
    local flag = flag or 0
    local id = id
    if type(id) == "string" then id = reaper.NamedCommandLookup(id) end
    reaper.Main_OnCommandEx(id, flag, self.pointer)
end

function ReaperProject:validatePointer(pointer, pointerType)
    return reaper.ValidatePtr2(self.pointer, pointer, pointerType)
end
function ReaperProject:wrapPointer(pointer, wrapperType, storageKey)
    if pointer == nil then return nil end
    -- This is slower but safer.
    --if self:validatePointer(pointer, wrapperType.pointerType) == false then return nil end
    self.wrappers = self.wrappers or {}
    self.wrappers[storageKey] = self.wrappers[storageKey] or {}
    local pointerStr = tostring(pointer)
    self.wrappers[storageKey][pointerStr] = self.wrappers[storageKey][pointerStr] or wrapperType:new{
        pointer = pointer,
        project = self
    }
    return self.wrappers[storageKey][pointerStr]
end
function ReaperProject:wrapTrack(pointer)     return self:wrapPointer(pointer, ReaperTrack, "tracks") end
function ReaperProject:wrapItem(pointer)      return self:wrapPointer(pointer, ReaperItem, "items") end
function ReaperProject:wrapTake(pointer)      return self:wrapPointer(pointer, ReaperTake, "takes") end
function ReaperProject:wrapEnvelope(pointer)  return self:wrapPointer(pointer, ReaperEnvelope, "envelopes") end
function ReaperProject:wrapPCMSource(pointer) return self:wrapPointer(pointer, ReaperPCMSource, "PCMSources") end

function ReaperProject:getName()
    return reaper.GetProjectName(self.pointer, "")
end

function ReaperProject:getItemCount()
    return reaper.CountMediaItems(self.pointer)
end

function ReaperProject:getSelectedItemCount()
    return reaper.CountSelectedMediaItems(self.pointer)
end

function ReaperProject:getTrackCount()
    return reaper.CountTracks(self.pointer)
end

function ReaperProject:getSelectedTrackCount()
    return reaper.CountSelectedTracks(self.pointer)
end

function ReaperProject:getItem(itemNumber)
    return self:wrapItem(reaper.GetMediaItem(self.pointer, itemNumber - 1))
end

function ReaperProject:getSelectedItem(itemNumber)
    return self:wrapItem(reaper.GetSelectedMediaItem(self.pointer, itemNumber - 1))
end

function ReaperProject:getTrack(trackNumber)
    return self:wrapTrack(reaper.GetTrack(self.pointer, trackNumber - 1))
end

function ReaperProject:getSelectedTrack(trackNumber)
    return self:wrapTrack(reaper.GetSelectedTrack(self.pointer, trackNumber - 1))
end

function ReaperProject:getItems()
    return self:getIterator(self.getItem, self.getItemCount)
end

function ReaperProject:getSelectedItems()
    return self:getIterator(self.getSelectedItem, self.getSelectedItemCount)
end

function ReaperProject:getTracks()
    return self:getIterator(self.getTrack, self.getTrackCount)
end

function ReaperProject:getSelectedTracks()
    return self:getIterator(self.getSelectedTrack, self.getSelectedTrackCount)
end

function ReaperProject:getEditCursorTime()
    return reaper.GetCursorPositionEx(self.pointer)
end

function ReaperProject:setEditCursorTime(time, moveView, seekPlay)
    if type(time) == "number" then
        reaper.SetEditCurPos2(self.pointer, time, moveView or false, seekPlay or true)
        return
    end
    reaper.SetEditCurPos2(self.pointer, time.time, time.moveView or false, time.seekPlay or true)
end

function ReaperProject:getPlayCursorTime()
    return reaper.GetPlayPositionEx(self.pointer)
end

function ReaperProject:isPlaying()
    return reaper.GetPlayStateEx(self.pointer) & 1 == 1
end

function ReaperProject:isPaused()
    return reaper.GetPlayStateEx(self.pointer) & 2 == 2
end

function ReaperProject:isRecording()
    return reaper.GetPlayStateEx(self.pointer) & 4 == 4
end

return ReaperProject