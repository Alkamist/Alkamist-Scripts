package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "API.Reaper Wrappers.ReaperPointerWrapper"

local ReaperTrack = { pointerType = "MediaTrack*" }
setmetatable(ReaperTrack, { __index = ReaperPointerWrapper })

ReaperTrack._members = {
    { key = "number",
        getter = function(self) return self:getNumber() end },

    { key = "items",
        getter = function(self) return self:getItems() end },

    { key = "selectedItems",
        getter = function(self) return self:getSelectedItems() end },
}

function ReaperTrack:new(object)
    local object = object or {}
    object._base = self
    setmetatable(object, object)
    ReaperPointerWrapper.init(object)
    return object
end

--------------------- Unique Functions  ---------------------


--------------------- Member Helper Functions  ---------------------

function ReaperTrack:getNumber()
    return reaper.GetMediaTrackInfo_Value(self.pointer, "IP_TRACKNUMBER")
end

function ReaperTrack:getItemCount()
    return reaper.GetTrackNumMediaItems(self.pointer)
end

function ReaperTrack:getSelectedItemCount()
    self.selectedItemNumbers = {}
    local selectedItemCount = 0
    for i = 1, self:getItemCount() do
        if reaper.IsMediaItemSelected(reaper.GetTrackMediaItem(self.pointer, i - 1)) then
            table.insert(self.selectedItemNumbers, i)
            selectedItemCount = selectedItemCount + 1
        end
    end
    return selectedItemCount
end

function ReaperTrack:getItem(itemNumber)
    return self.project:wrapItem(reaper.GetTrackMediaItem(self.pointer, itemNumber - 1))
end

function ReaperTrack:getSelectedItem(itemNumber)
    local itemNumber = self.selectedItemNumbers[itemNumber]
    if itemNumber then return self:getItem(itemNumber) end
    return nil
end

function ReaperTrack:getItems()
    return ReaperPointerWrapper.getIterator(self, self.getItem, self.getItemCount)
end

function ReaperTrack:getSelectedItems()
    self:getSelectedItemCount()
    return ReaperPointerWrapper.getIterator(self, self.getSelectedItem, self.getSelectedItemCount)
end

return ReaperTrack