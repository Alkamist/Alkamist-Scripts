local PointerWrapper = require "API.Reaper Wrappers.PointerWrapper"

local function Track(project, pointer)
    if project == nil then return nil end
    if pointer == nil then return nil end

    local track = PointerWrapper(pointer, "MediaTrack*")

    -- Private Members:

    local _project = project

    local function getSelectedItemNumbers(track)
        local selectedItemNumbers = {}
        for i = 1, track:getItemCount() do
            if reaper.IsMediaItemSelected(reaper.GetTrackMediaItem(track:getPointer(), i - 1)) then
                table.insert(selectedItemNumbers, i)
            end
        end
        return selectedItemNumbers
    end

    -- Getters:

    function track:getProject()        return _project end
    function track:getNumber()         return reaper.GetMediaTrackInfo_Value(self:getPointer(), "IP_TRACKNUMBER") end
    function track:getItemCount()      return reaper.GetTrackNumMediaItems(self:getPointer()) end
    function track:getItem(itemNumber) return self:getProject():wrapItem(reaper.GetTrackMediaItem(self:getPointer(), itemNumber - 1)) end
    function track:getItems()          return self:getProject():getIterator(self, self.getItem, self.getItemCount) end
    function track:getSelectedItemCount()
        local selectedItemNumbers = getSelectedItemNumbers(self)
        local selectedItemCount = 0
        for index, itemNumber in ipairs(selectedItemNumbers) do
            if reaper.IsMediaItemSelected(reaper.GetTrackMediaItem(self:getPointer(), itemNumber - 1)) then
                selectedItemCount = index
            end
        end
        return selectedItemCount
    end
    function track:getSelectedItem(itemNumber)
        local selectedItemNumbers = getSelectedItemNumbers(self)
        local itemNumber = selectedItemNumbers[itemNumber]
        if itemNumber then return self:getItem(itemNumber) end
        return nil
    end
    function track:getSelectedItems() return self:getProject():getIterator(self, self.getSelectedItem, self.getSelectedItemCount) end

    -- Setters:

    return track
end

return Track