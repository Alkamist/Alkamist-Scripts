-- @description Zoom Tool Default Settings
-- @version 1.6.1
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
--   + Split the sensitivities into arrange and MIDI editor parts, so you can set them
--     individually if you want. You will have to update your user settings file.



--[[

DO NOT CHANGE THIS FILE. INSTEAD, COPY THIS FILE AS:

"Scripts\Alkamist Scripts\Zoom Tool\Zoom Tool User Settings.lua"

AND CHANGE THE SETTINGS THERE.

]]--



-- Change these sensitivities to change the feel of the zoom tool.
xSensitivityArrange = 1.0
ySensitivityArrange = 1.0
xSensitivityMIDIEditor = 1.0
ySensitivityMIDIEditor = 1.0

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

-- If this is enabled, the script will zoom the master track (if visible in the TCP)
-- with the rest of the other tracks.
zoomMasterWithOtherTracks = true