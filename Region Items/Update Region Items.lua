label = 'Alkamist: Update Region Items'

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. '?.lua;' .. package.path
require "Scripts.Alkamist.Region Items.Region Functions"

function updateRegionItems()
    --local startTime = reaper.time_precise()
    reaperCMD("_SWS_SAVETIME1")
    reaperCMD("_SWS_SAVEVIEW")
    reaperCMD("_BR_SAVE_CURSOR_POS_SLOT_1")

    reaperCMD("_SWS_MVPWIDOFF") -- turn moving envelopes with items off
    reaperCMD(40928) -- disable auto crossfade on split
    reaperCMD(41195) -- enable auto fade-in/fade-out
    reaperCMD(40309) -- disable ripple editing

    -- Save the initial track and item selection.
    local initialTrackSelection = getSelectedTracks()
    local initalItemSelection = getSelectedItems()

    -- Determine if we even have any region items selected.
    local numSelectedStartingItems = reaper.CountSelectedMediaItems(0)
    if numSelectedStartingItems ~= 1 then
        return -1
    end

    local sourceRegion = reaper.GetSelectedMediaItem(0, 0)

    -- Check to make sure the region track has children.
    selectChildTracks(sourceRegion)
    if reaper.CountSelectedTracks(0) <= 0 then
        return -2
    end

    populateSourceEnvelopes(sourceRegion)
    local regionItems = getRegionItems(sourceRegion)

    -- The script doesn't work properly unless all of the tracks in the
    -- region are visible during processing.
    showAllTracksInRegion(sourceRegion)

    -- We need to show all envelopes for the script to work properly.
    reaperCMD(41149) -- show all envelopes for all tracks

    -- Clean up the destination regions before transfer.
    for i = 1, #regionItems do
        clearRegion(regionItems[i])
    end

    -- We need to keep track of the garbage tracks that are made for spacing.
    local garbageTracks = {}

    -- Transfer over the automation with the help of automation items.
    insertTransferItems(sourceRegion, sourceRegion)
    for i = 1, #regionItems do
        garbageTracks[i] = {}
        garbageTracks[i] = prepareDestinationForTransfer(sourceRegion, regionItems[i])
        insertTransferItems(sourceRegion, regionItems[i])
    end
    removeSourceTransferItems(sourceRegion)

    -- Transfer over and pool any extra automation items that are present in
    -- the source region.
    copySourceAutomationItems(sourceRegion)
    for i = 1, #regionItems do
        removeAutomationItems(regionItems[i])
        pasteSourceAutomationItems(sourceRegion, regionItems[i])
    end

    -- Copy over the media items.
    local itemsWereCopied, itemPasteOffset, pasteTrackOffset = copyChildItems(sourceRegion)
    for i = 1, #regionItems do
        -- Only paste items if there are items to paste.
        if itemsWereCopied then
            pasteChildItems(sourceRegion, regionItems[i], itemPasteOffset, pasteTrackOffset)
        end
    end

    -- Remove the garbage tracks that were made for spacing.
    for i = 1, #garbageTracks do
        restoreSelectedTracks(garbageTracks[i])
        reaperCMD(40005) -- remove tracks
    end

    -- Restore the initial track and item selection.
    restoreSelectedTracks(initialTrackSelection)
    restoreSelectedItems(initalItemSelection)

    reaperCMD(41196) -- disable auto fade-in/fade-out
    reaperCMD("_BR_RESTORE_CURSOR_POS_SLOT_1")
    reaperCMD("_SWS_RESTOREVIEW")
    reaperCMD("_SWS_RESTTIME1")

    --msg(reaper.time_precise() - startTime)

    return 0
end

-- Check for errors and start the script.
if(reaper.CountSelectedMediaItems(0) > 0) then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    local errorResult = updateRegionItems()
    if errorResult == -1 then
        reaper.ShowMessageBox("Please select only one region item.", "Error!", 0)
    elseif errorResult == -2 then
        reaper.ShowMessageBox("The track of the region item must have children.", "Error!", 0)
    end

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock(label, -1)
end

reaper.UpdateArrange()