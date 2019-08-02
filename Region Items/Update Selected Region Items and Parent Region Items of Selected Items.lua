-- @description Update Selected Region Items and Parent Region Items of Selected Items
-- @author Alkamist
-- @noindex

--   This action is identical to "Update Parent Region Items of Selected Items", except
--   it will first update any region items you have selected.

label = 'Alkamist: Update Parent Region Items of Selected Items'

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. '?.lua;' .. package.path
require "Scripts.Alkamist Scripts.Region Items.Region Item Functions"

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