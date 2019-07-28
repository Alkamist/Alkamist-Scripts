-- @description Zoom Tool Default Settings
-- @version 1.5.5
-- @author Alkamist
-- @donate https://paypal.me/CoreyLehmanMusic
-- @about
--   This script will activate a zoom tool similar to what is used in Melodyne.
-- @changelog
--   + Fixed default settings file description.



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