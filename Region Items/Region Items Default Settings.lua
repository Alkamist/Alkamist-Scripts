-- @description Region Items Default Settings
-- @version 1.2.2
-- @author Alkamist
-- @donate https://paypal.me/CoreyLehmanMusic
-- @about
--   This is the default settings file for the Region Items scripts. You need this file
--   installed in the proper directory for script to work:
--
--   "Scripts\Alkamist Scripts\Region Items\Region Items Default Settings.lua"
--
--   You can copy this file into the same folder and call it "Region Items User Settings.lua"
--   and change the settings in there. That way, your settings are not overwritten
--   when updating.
-- @changelog
--   + Fixed problem when fade-in and fade-out got applied to the same item.
--   + Made auto-fade setting less likely to wrongly change.



--[[

DO NOT CHANGE THIS FILE. INSTEAD, COPY THIS FILE AS:

"Scripts\Alkamist Scripts\Region Items\Region Items User Settings.lua"

AND CHANGE THE SETTINGS THERE.

]]--



-- Change this to true to enable regions to be processed based on identical item names
-- instead of by MIDI pool.
selectRegionsByName = false

-- If set to true, this setting will cause the script to pool the pasted MIDI items
-- regardless of your preferences. If it is false, the pasted items will pool depending
-- on your setting of "Pool MIDI source data when pasting or duplicating media items"
-- in Reaper's preferences page.
poolPastedMIDIItems = true