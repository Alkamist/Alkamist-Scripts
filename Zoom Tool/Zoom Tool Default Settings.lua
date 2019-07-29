-- @description Zoom Tool Default Settings
-- @version 1.5.10
-- @author Alkamist
-- @donate https://paypal.me/CoreyLehmanMusic
-- @about
--   This is the default settings file for the Zoom Tool. You need this file
--   installed in the proper directory for script to work:
--
--   "Scripts\Alkamist Scripts\Zoom Tool\Zoom Tool Default Settings.lua"
--
--   You can copy this file into the same folder and call it "Zool Tool User Settings.lua"
--   and change the settings in there. That way, your settings are not overwritten
--   when updating.
-- @changelog
--   + Added an experimental vertical centering systems. It can be enabled in the settings.



--[[

DO NOT CHANGE THIS FILE. INSTEAD, COPY THIS FILE AS:

"Scripts\Alkamist Scripts\Zoom Tool\Zoom Tool User Settings.lua"

AND CHANGE THE SETTINGS THERE.

]]--



-- Change these sensitivities to change the feel of the zoom tool.
xSensitivity = 1.0
ySensitivity = 1.0

-- If this is true, the script will precisely scroll to the horizontal position
-- you have your mouse over in the main view. This introduces some graphical
-- glitches.
usePreciseMainViewHorizontalPositionTracking = true

-- Change this if you want to use action-based vertical zoom in the main view
-- vs. setting the track height directly.
useActionBasedVerticalZoom = false

-- These are the minimum heights of standard envelopes and the master track.
-- Change these if you need to, but I am not aware of any reason to do so.
-- Changing these to the wrong value will cause unintended scrolling while zooming.
minimumEnvelopeHeight = 24
minimumMasterHeight = 74

-- If this is enabled, the script will try to pull the track/envelope that is under
-- the mouse cursor to the center of the screen while zooming.
shouldCenterVertically = false