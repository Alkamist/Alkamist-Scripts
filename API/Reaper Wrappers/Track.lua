local PointerWrapper = require "API.Reaper Wrappers.PointerWrapper"

local Track = setmetatable({}, { __index = PointerWrapper })

function Track:new(project, pointer)
    if project == nil then return nil end
    if pointer == nil then return nil end

    local base = PointerWrapper:new(pointer, "MediaTrack*")
    local self = setmetatable(base, { __index = self })
    self._project = project

    return self
end

-- Getters:

function Track:getSelectedItemNumbers()
    local selectedItemNumbers = {}
    for i = 1, self:getItemCount() do
        if reaper.IsMediaItemSelected(reaper.GetTrackMediaItem(self:getPointer(), i - 1)) then
            table.insert(selectedItemNumbers, i)
        end
    end
    return selectedItemNumbers
end
function Track:getProject()        return _project end
function Track:getNumber()         return reaper.GetMediaTrackInfo_Value(self:getPointer(), "IP_TRACKNUMBER") end
function Track:getItemCount()      return reaper.GetTrackNumMediaItems(self:getPointer()) end
function Track:getItem(itemNumber) return self:getProject():wrapItem(reaper.GetTrackMediaItem(self:getPointer(), itemNumber - 1)) end
function Track:getItems()          return self:getIterator(self.getItem, self.getItemCount) end
function Track:getSelectedItemCount()
    local selectedItemNumbers = self:getSelectedItemNumbers(self)
    local selectedItemCount = 0
    for index, itemNumber in ipairs(selectedItemNumbers) do
        if reaper.IsMediaItemSelected(reaper.GetTrackMediaItem(self:getPointer(), itemNumber - 1)) then
            selectedItemCount = index
        end
    end
    return selectedItemCount
end
function Track:getSelectedItem(itemNumber)
    local selectedItemNumbers = self:getSelectedItemNumbers(self)
    local itemNumber = selectedItemNumbers[itemNumber]
    if itemNumber then return self:getItem(itemNumber) end
    return nil
end
function Track:getSelectedItems() return self:getIterator(self.getSelectedItem, self.getSelectedItemCount) end

return Track