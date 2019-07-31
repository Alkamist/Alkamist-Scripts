-- @description Update Parent Region Items of Selected Items
-- @author Alkamist
-- @noindex

label = 'Alkamist: Update Parent Region Items of Selected Items'

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. '?.lua;' .. package.path
require "Scripts.Alkamist Scripts.Region Items.Region Item Functions"

function updateParentRegionItemsOfSelectedItems()
    local selectedItems = getSelectedItems()
    local sourceItems = {}

    local sourceItemIndex = 1
    for i = 1, #selectedItems do
        local item = selectedItems[i]
        local itemPosition = getItemPosition(item)
        local itemTrack = getItemTrack(item)

        if reaper.GetParentTrack(itemTrack) then
            local parentTrack = reaper.GetParentTrack(itemTrack)

            while parentTrack do
                for j = 1, reaper.GetTrackNumMediaItems(parentTrack) do
                    local possibleRegionItem = reaper.GetTrackMediaItem(parentTrack, j - 1)

                    if itemIsWithinRegion(possibleRegionItem, item) then
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

                parentTrack = reaper.GetParentTrack(parentTrack)
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
    updateParentRegionItemsOfSelectedItems()
    restoreSettings()

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock(label, -1)
end

reaper.UpdateArrange()