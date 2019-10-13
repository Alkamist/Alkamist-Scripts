package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local ReaperProject = {
    pointerType = "ReaProject*",
    name = "ReaperProject"
}

local ReaperProject_mt = {

    -- Getters
    __index = function(tbl, key)
        if key == "name" then return reaper.GetProjectName(tbl.pointer, "") end
        if key == "itemCount" then return reaper.CountMediaItems(tbl.pointer) end
        if key == "selectedItemCount" then return reaper.CountSelectedMediaItems(tbl.pointer) end
        if key == "items" then return tbl:getItems() end
        if key == "selectedItems" then return tbl:getSelectedItems() end
        if key == "trackCount" then return reaper.CountTracks(tbl.pointer) end
        if key == "selectedTrackCount" then return reaper.CountSelectedTracks(tbl.pointer) end
        if key == "tracks" then return tbl:getTracks() end
        if key == "selectedTracks" then return tbl:getSelectedTracks() end
        return ReaperProject[key]
    end,

    -- Setters
    __newindex = function(tbl, key, value)
        if key == "name" then return end
        if key == "itemCount" then return end
        if key == "selectedItemCount" then return end
        if key == "items" then return end
        if key == "selectedItems" then return end
        if key == "trackCount" then return end
        if key == "selectedTrackCount" then return end
        if key == "tracks" then return end
        if key == "selectedTracks" then return end
        rawset(tbl, key, value)
    end

}

function ReaperProject:new(object)
    local object = object or {}
    setmetatable(object, ReaperProject_mt)
    return object
end

function ReaperProject:isValid()
    return self.pointer ~= nil and reaper.ValidatePtr(self.pointer, self.pointerType)
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