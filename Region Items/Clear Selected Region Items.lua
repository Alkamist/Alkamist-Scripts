-- @description Clear Selected Region Items
-- @author Alkamist
-- @noindex

--   This action clears the contained contents of the child tracks of the selected
--   region items. Used to clean up the contents of a region item if you want to change,
--   move, or remove it.

label = 'Alkamist: Clear Selected Region Items'

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. '?.lua;' .. package.path
require "Scripts.Alkamist Scripts.Region Items.Region Item Functions"

local projRipEdit = nil
local initialTrackSelection = {}
local initalItemSelection = {}
function saveSettings()
    reaperCMD("_SWS_SAVETIME1")
    reaperCMD("_SWS_SAVEVIEW")
    reaperCMD("_BR_SAVE_CURSOR_POS_SLOT_1")

    -- Save the previous ripple editing setting before we temporarily change it.
    projRipEdit = reaper.SNM_GetIntConfigVar("projripedit", 0)

    -- Save the initial track and item selection.
    initialTrackSelection = getSelectedTracks()
    initalItemSelection = getSelectedItems()
end

function restoreSettings()
    -- Restore the settings we changed.
    reaper.SNM_SetIntConfigVar("projripedit", projRipEdit)
    reaperCMD("_BR_RESTORE_CURSOR_POS_SLOT_1")
    reaperCMD("_SWS_RESTOREVIEW")
    reaperCMD("_SWS_RESTTIME1")

    -- Restore the initial track and item selection.
    restoreSelectedTracks(initialTrackSelection)
    restoreSelectedItems(initalItemSelection)
end

function clearSelectedRegionItems()
    reaperCMD(40309) -- disable ripple editing

    -- Save the initial track and item selection.
    local initialTrackSelection = getSelectedTracks()
    local initalItemSelection = getSelectedItems()

    local selectedItems = getSelectedRegionItems()

    -- We need to show all envelopes for the script to work properly.
    reaperCMD(41149) -- show all envelopes for all tracks

    for i = 1, #selectedItems do
        clearRegion(selectedItems[i])
    end
end

-- Start the script if there are items selected.
if reaper.CountSelectedMediaItems(0) > 0 then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    saveSettings()
    clearSelectedRegionItems()
    restoreSettings()

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock(label, -1)
end

reaper.UpdateArrange()