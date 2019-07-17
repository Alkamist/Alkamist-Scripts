label = 'Alkamist: Clear Selected Region Items'

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. '?.lua;' .. package.path
require "Scripts.Alkamist.Region Items.Region Functions"

function clearSelectedRegionItems()
    reaperCMD("_SWS_SAVETIME1")
    reaperCMD("_SWS_SAVEVIEW")
    reaperCMD("_BR_SAVE_CURSOR_POS_SLOT_1")
    reaperCMD(40309) -- disable ripple editing

    -- Save the initial track and item selection.
    local initialTrackSelection = getSelectedTracks()
    local initalItemSelection = getSelectedItems()

    local selectedItems = getSelectedMIDIItems()

    -- We need to show all envelopes for the script to work properly.
    reaperCMD(41149) -- show all envelopes for all tracks

    for i = 1, #selectedItems do
        clearRegion(selectedItems[i])
    end

    -- Restore the initial track and item selection.
    restoreSelectedTracks(initialTrackSelection)
    restoreSelectedItems(initalItemSelection)

    reaperCMD("_BR_RESTORE_CURSOR_POS_SLOT_1")
    reaperCMD("_SWS_RESTOREVIEW")
    reaperCMD("_SWS_RESTTIME1")

    return 0
end

-- Check for errors and start the script.
if(reaper.CountSelectedMediaItems(0) > 0) then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    local errorResult = clearSelectedRegionItems()

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock(label, -1)
end

reaper.UpdateArrange()