package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"
local factory = require "Pitch Correction.Reaper Wrapper Factory"

local AlkAPI = {}

function AlkAPI.getSelectedItems(projectIndex)
    if projectIndex == nil then projectIndex = 1 end
    local selectedItems = {}
    for index = 1, AlkWrap.getNumSelectedItems(projectIndex) do
        table.insert(selectedItems,
                     factory.createNew("ReaperItem", AlkWrap.getSelectedItem(projectIndex, index)))
    end
    return selectedItems
end

return AlkAPI