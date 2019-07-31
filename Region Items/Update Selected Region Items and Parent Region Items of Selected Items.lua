-- @description Update Parent Region Items of Selected Items
-- @author Alkamist
-- @noindex

--   This action is identical to "Update Parent Region Items of Selected Items", except
--   it will first update any region items you have selected.

label = 'Alkamist: Update Parent Region Items of Selected Items'

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. '?.lua;' .. package.path
require "Scripts.Alkamist Scripts.Region Items.Region Item Functions"

-- In case I need to set up a region item check later.
function itemIsRegionItem(item)
    return true
end

function getParentTrack(track, receiveNumber)
    local trackNumReceives = reaper.GetTrackNumSends(track, -1)
    local parentTrack = nil
    local receiveNumberIsInvalid = false

    if receiveNumber <= trackNumReceives and trackNumReceives > 0 then
        parentTrack = reaper.GetTrackSendInfo_Value(track, -1, receiveNumber - 1, "P_SRCTRACK")

    else
        parentTrack = reaper.GetParentTrack(track)
        receiveNumberIsInvalid = true
    end

    return parentTrack, receiveNumberIsInvalid
end

function updateParentRegionItemsOfSelectedItems()
    local selectedItems = getSelectedItems()
    local sourceItems = {}

    local sourceItemIndex = 1
    for i = 1, #selectedItems do
        local item = selectedItems[i]
        local itemPosition = getItemPosition(item)
        local itemTrack = getItemTrack(item)

        local receiveNumber = 1
        local parentTrack, receiveNumberIsInvalid = getParentTrack(itemTrack, receiveNumber)
        local currentTrack = itemTrack

        while parentTrack do
            for j = 1, reaper.GetTrackNumMediaItems(parentTrack) do
                local possibleRegionItem = reaper.GetTrackMediaItem(parentTrack, j - 1)

                if itemIsWithinRegion(possibleRegionItem, item) and itemIsRegionItem(possibleRegionItem) then
                    local regionItemIsAlreadyInSourceList = false
                    for k = 1, #sourceItems do
                        if possibleRegionItem == sourceItems[k] then
                            regionItemIsAlreadyInSourceList = true
                        end
                    end

                    if not regionItemIsAlreadyInSourceList then
                        sourceItems[sourceItemIndex] = possibleRegionItem
                        sourceItemIndex = sourceItemIndex + 1
                    end
                end
            end

            receiveNumber = receiveNumber + 1
            parentTrack, receiveNumberIsInvalid = getParentTrack(currentTrack, receiveNumber)

            if receiveNumberIsInvalid then
                parentTrack = getParentTrack(currentTrack, receiveNumber)
                currentTrack = parentTrack
                receiveNumber = 0
            end
        end
    end

    for i = 1, #sourceItems do
        updateRegionItems(sourceItems[i])
    end

    restoreSelectedItems(selectedItems)
end

-- Start the script if there are items selected.
if (reaper.CountSelectedMediaItems(0) > 0) then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    saveSettings()
    updateRegionItemsOfSelectedSourceItems()
    updateParentRegionItemsOfSelectedItems()
    restoreSettings()

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock(label, -1)
end

reaper.UpdateArrange()