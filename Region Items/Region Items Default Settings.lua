-- @description Region Items Default Settings
-- @author Alkamist
-- @noindex




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