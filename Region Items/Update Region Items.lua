-- @description Update Region Items
-- @version 1.2.1
-- @author Alkamist
-- @donate https://paypal.me/CoreyLehmanMusic
-- @about
--   This action will copy the items and automation of all child tracks underneath
--   and within the bounds of a single selected region item. It will then paste those
--   contents to the child tracks of all paired region items, removing their previous
--   contents.
--   Paired region items are determined by either MIDI pool or item name, depending on
--   the value of the "selectRegionsByName" bool in the settings file.
-- @changelog
--   + Added the setting "poolPastedMIDIItems", which will cause the pasted midi items to
--     pool regardless of your Reaper preferences.

label = 'Alkamist: Update Region Items'

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. '?.lua;' .. package.path
require "Scripts.Alkamist Scripts.Region Items.Region Item Functions"

local envAttach = nil
local splitAutoXFade = nil
local projRipEdit = nil
local initialTrackSelection = {}
local initalItemSelection = {}
function saveSettings()
    reaperCMD("_SWS_SAVETIME1")
    reaperCMD("_SWS_SAVEVIEW")
    reaperCMD("_BR_SAVE_CURSOR_POS_SLOT_1")

    -- Save the previous settings before we temporarily change them.
    envAttach = reaper.SNM_GetIntConfigVar("envattach", 0)
    splitAutoXFade = reaper.SNM_GetIntConfigVar("splitautoxfade", 0)
    projRipEdit = reaper.SNM_GetIntConfigVar("projripedit", 0)

    -- Save the initial track and item selection.
    initialTrackSelection = getSelectedTracks()
    initalItemSelection = getSelectedItems()
end

function restoreSettings()
    -- Restore the settings we changed.
    reaper.SNM_SetIntConfigVar("envattach", envAttach)
    reaper.SNM_SetIntConfigVar("splitautoxfade", splitAutoXFade)
    reaper.SNM_SetIntConfigVar("projripedit", projRipEdit)
    reaperCMD("_BR_RESTORE_CURSOR_POS_SLOT_1")
    reaperCMD("_SWS_RESTOREVIEW")
    reaperCMD("_SWS_RESTTIME1")

    -- Restore the initial track and item selection.
    restoreSelectedTracks(initialTrackSelection)
    restoreSelectedItems(initalItemSelection)
end

function updateRegionItems()
    saveSettings()

    reaperCMD("_SWS_MVPWIDOFF") -- turn moving envelopes with items off
    reaperCMD(40928) -- disable auto crossfade on split
    reaperCMD(41195) -- enable auto fade-in/fade-out
    reaperCMD(40309) -- disable ripple editing

    -- Determine if we even have any region items selected.
    local numSelectedStartingItems = reaper.CountSelectedMediaItems(0)
    if numSelectedStartingItems ~= 1 then
        return "more_than_one_item"
    end

    local sourceRegion = reaper.GetSelectedMediaItem(0, 0)

    -- Check to make sure the region track has children.
    selectChildTracks(sourceRegion)
    if reaper.CountSelectedTracks(0) <= 0 then
        return "no_children"
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

    restoreSettings()

    return 0
end

-- Check for errors and start the script.
if(reaper.CountSelectedMediaItems(0) > 0) then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    local errorResult = updateRegionItems()
    if errorResult == "more_than_one_item" then
        reaper.ShowMessageBox("Please select only one region item.", "Error!", 0)
        restoreSettings()
    elseif errorResult == "no_children" then
        reaper.ShowMessageBox("The track of the region item must have children.", "Error!", 0)
        restoreSettings()
    end

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock(label, -1)
end

reaper.UpdateArrange()