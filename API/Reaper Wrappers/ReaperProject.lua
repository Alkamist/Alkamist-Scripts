package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "API.Reaper Wrappers.ReaperPointerWrapper"

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

--------------------- Unique Functions  ---------------------

--

--------------------- Member Helper Functions  ---------------------

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
    return ReaperPointerWrapper.getIterator(self, self.getItem)
end

function ReaperProject:getSelectedItems()
    return ReaperPointerWrapper.getIterator(self, self.getSelectedItem)
end

function ReaperProject:getTracks()
    return ReaperPointerWrapper.getIterator(self, self.getTrack)
end

function ReaperProject:getSelectedTracks()
    return ReaperPointerWrapper.getIterator(self, self.getSelectedTrack)
end

return ReaperProject