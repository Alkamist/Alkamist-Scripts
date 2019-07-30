-- @description Region Items Default Settings
-- @version 1.2
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
--   + Added the ability to process regions based on item name instead of pooling.
--     To enable this option, copy the Region Items Default Settings.lua file to
--     the location: "Scripts\Alkamist Scripts\Region Items\Region Items User Settings.lua"
--     and change the "selectRegionsByName" bool to true.



--[[

DO NOT CHANGE THIS FILE. INSTEAD, COPY THIS FILE AS:

"Scripts\Alkamist Scripts\Region Items\Region Items User Settings.lua"

AND CHANGE THE SETTINGS THERE.

]]--



-- Change this to true to enable regions to be processed based on identical item names
-- instead of by MIDI pool.
selectRegionsByName = false