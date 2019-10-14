package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "API.Reaper Wrappers.ReaperPointerWrapper"
local ReaperTrack = require "API.Reaper Wrappers.ReaperTrack"
local ReaperEnvelope = require "API.Reaper Wrappers.ReaperEnvelope"
local ReaperItem = require "API.Reaper Wrappers.ReaperItem"
local ReaperTake = require "API.Reaper Wrappers.ReaperTake"
local ReaperPCMSource = require "API.Reaper Wrappers.ReaperPCMSource"

local ReaperProject = { pointerType = "ReaProject*" }
setmetatable(ReaperProject, { __index = ReaperPointerWrapper })

ReaperProject._members = {
    { key = "name",
        getter = function(self) return reaper.GetProjectName(self.pointer, "") end },

    { key = "items",
        getter = function(self) return self:getItems() end },

    { key = "selectedItems",
        getter = function(self) return self:getSelectedItems() end },

    { key = "tracks",
        getter = function(self) return self:getTracks() end },

    { key = "selectedTracks",
        getter = function(self) return self:getSelectedTracks() end },
}

function ReaperProject:new(object)
    local object = object or {}
    object._base = self
    setmetatable(object, object)
    ReaperPointerWrapper.init(object)
    return object
end

--------------------- Unique Functions  ---------------------

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
    self.wrappers = self.wrappers or {}
    self.wrappers[storageKey] = self.wrappers[storageKey] or {}
    local pointerStr = tostring(pointer)
    --if self:validatePointer(pointer, wrapperType.pointerType) then
    self.wrappers[storageKey][pointerStr] = self.wrappers[storageKey][pointerStr] or wrapperType:new{
        pointer = pointer,
        project = self
    }
    --end
    return self.wrappers[storageKey][pointerStr]
end
function ReaperProject:wrapTrack(pointer) return self:wrapPointer(pointer, ReaperTrack, "tracks") end
function ReaperProject:wrapItem(pointer) return self:wrapPointer(pointer, ReaperItem, "items") end
function ReaperProject:wrapTake(pointer) return self:wrapPointer(pointer, ReaperTake, "takes") end
function ReaperProject:wrapEnvelope(pointer) return self:wrapPointer(pointer, ReaperEnvelope, "envelopes") end
function ReaperProject:wrapPCMSource(pointer) return self:wrapPointer(pointer, ReaperPCMSource, "PCMSources") end

--------------------- Member Helper Functions  ---------------------

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
    return ReaperPointerWrapper.getIterator(self, self.getItem, self.getItemCount)
end

function ReaperProject:getSelectedItems()
    return ReaperPointerWrapper.getIterator(self, self.getSelectedItem, self.getSelectedItemCount)
end

function ReaperProject:getTracks()
    return ReaperPointerWrapper.getIterator(self, self.getTrack, self.getTrackCount)
end

function ReaperProject:getSelectedTracks()
    return ReaperPointerWrapper.getIterator(self, self.getSelectedTrack, self.getSelectedTrackCount)
end

return ReaperProject