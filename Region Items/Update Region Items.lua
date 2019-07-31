-- @description Region Items (4 actions)
-- @version 1.3
-- @author Alkamist
-- @donate https://paypal.me/CoreyLehmanMusic
-- @provides
--   [main] .
--   [main] . > Clear Selected Region Items.lua
--   [main] . > Update Parent Region Items of Selected Items.lua
--   [main] . > Update Selected Region Items and Parent Region Items of Selected Items.lua
--   Region Item Functions.lua
--   Region Items Default Settings.lua
-- @about
--   This installation will include 4 actions:
--
--   - Update Region Items
--
--   This action will copy the items and automation of all child tracks underneath
--   and within the bounds of the selected region items. It will then paste those
--   contents to the child tracks of all paired region items, removing their previous
--   contents.
--   Paired region items are determined by either MIDI pool or item name, depending on
--   the value of the "selectRegionsByName" bool in the settings file.
--
--   - Update Parent Region Items of Selected Items
--
--   This action will navigate through all of the parent tracks of the selected items
--   (including source tracks of receives) and update any parent region items they are
--   contained within.
--
--   - Update Selected Region Items and Parent Region Items of Selected Items
--
--   This action is identical to "Update Parent Region Items of Selected Items", except
--   it will first update any region items you have selected.
--
--   - Clear Selected Region Items
--
--   This action clears the contained contents of the child tracks of the selected
--   region items. Used to clean up the contents of a region item if you want to change,
--   move, or remove it.
-- @changelog
--   + Made "Update Region Items" able to be called on multiple selected source regions.
--     Be careful you don't have multiple of the same region item selected though,
--     since there is no way for the script to discern which region item you intended
--     to be the source of the update.
--   + Added the action "Update Parent Region Items of Selected Items".
--   + Added the action "Update Selected Region Items and Parent Region Items of Selected Items".

label = 'Alkamist: Update Region Items'

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. '?.lua;' .. package.path
require "Scripts.Alkamist Scripts.Region Items.Region Item Functions"

-- Start the script if there are items selected.
if reaper.CountSelectedMediaItems(0) > 0 then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    saveSettings()
    updateRegionItemsOfSelectedSourceItems()
    restoreSettings()

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock(label, -1)
end

reaper.UpdateArrange()