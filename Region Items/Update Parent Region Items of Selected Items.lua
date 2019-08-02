-- @description Update Parent Region Items of Selected Items
-- @author Alkamist
-- @noindex

--   This action will navigate through all of the parent tracks of the selected items
--   (including source tracks of receives) and update any parent region items they are
--   contained within.

label = 'Alkamist: Update Parent Region Items of Selected Items'

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. '?.lua;' .. package.path
require "Scripts.Alkamist Scripts.Region Items.Region Item Functions"

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