package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "Pitch Correction.Reaper Wrappers.ReaperPointerWrapper"

local ReaperProject = { pointerType = "ReaProject*" }
setmetatable(ReaperProject, { __index = ReaperPointerWrapper })

ReaperProject._members = {
    { key = "name",
        getter = function(self) return reaper.GetProjectName(self.pointer, "") end },

    { key = "itemCount",
        getter = function(self) return reaper.CountMediaItems(self.pointer) end },

    { key = "selectedItemCount",
        getter = function(self) return reaper.CountSelectedMediaItems(self.pointer) end },

    { key = "items",
        getter = function(self) return self:getItems() end },

    { key = "selectedItems",
        getter = function(self) return self:getSelectedItems() end },

    { key = "trackCount",
        getter = function(self) return reaper.CountTracks(self.pointer) end },

    { key = "selectedTrackCount",
        getter = function(self) return reaper.CountSelectedTracks(self.pointer) end },

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

function ReaperProject:getItem(itemNumber)
    return self.factory.createNew(reaper.GetMediaItem(self.pointer, itemNumber - 1))
end

function ReaperProject:getItems()
    local output = {}
    for i = 1, self.itemCount do
        table.insert(output, self:getItem(i))
    end
    return output
end

function ReaperProject:getSelectedItem(itemNumber)
    return self.factory.createNew(reaper.GetSelectedMediaItem(self.pointer, itemNumber - 1))
end

function ReaperProject:getSelectedItems()
    local output = {}
    for i = 1, self.selectedItemCount do
        table.insert(output, self:getItem(i))
    end
    return output
end

function ReaperProject:getTrack(trackNumber)
    return self.factory.createNew(reaper.GetTrack(self.pointer, trackNumber - 1))
end

function ReaperProject:getTracks()
    local output = {}
    for i = 1, self.trackCount do
        table.insert(output, self:getTrack(i))
    end
    return output
end

function ReaperProject:getSelectedTrack(trackNumber)
    return self.factory.createNew(reaper.GetSelectedTrack(self.pointer, trackNumber - 1))
end

function ReaperProject:getSelectedTracks()
    local output = {}
    for i = 1, self.selectedTrackCount do
        table.insert(output, self:getSelectedTrack(i))
    end
    return output
end

return ReaperProject