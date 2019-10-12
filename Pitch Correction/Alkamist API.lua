package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"
local ReaperItem = require "Pitch Correction.Reaper Wrappers.ReaperItem"

local ReaperWrapperFactory = {}
function ReaperWrapperFactory:new(object)
    local object = object or {}
    setmetatable(object, { __index = self })
    return object
end

function ReaperWrapperFactory:newMediaItem(itemPointer)
    return ReaperItem:new{
        pointer = AlkWrap.getSelectedItem(projectIndex, index)
    }
end

local factory = ReaperWrapperFactory:new()

local AlkAPI = {}

function AlkAPI.getSelectedItems(projectIndex)
    if projectIndex == nil then projectIndex = 1 end
    local selectedItems = {}
    for index = 1, AlkWrap.getNumSelectedItems(projectIndex) do
        table.insert(selectedItems, factory:newMediaItem(AlkWrap.getSelectedItem(projectIndex, index)))
    end
    return selectedItems
end

return AlkAPI