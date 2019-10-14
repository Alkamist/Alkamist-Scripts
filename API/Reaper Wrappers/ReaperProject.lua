package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "API.Reaper Wrappers.ReaperPointerWrapper"

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

--

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
    return self.factory.createNew(reaper.GetMediaItem(self.pointer, itemNumber - 1))
end

function ReaperProject:getSelectedItem(itemNumber)
    return self.factory.createNew(reaper.GetSelectedMediaItem(self.pointer, itemNumber - 1))
end

function ReaperProject:getTrack(trackNumber)
    return self.factory.createNew(reaper.GetTrack(self.pointer, trackNumber - 1))
end

function ReaperProject:getSelectedTrack(trackNumber)
    return self.factory.createNew(reaper.GetSelectedTrack(self.pointer, trackNumber - 1))
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