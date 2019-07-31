-- @description Zoom Tool Default Settings
-- @author Alkamist
-- @noindex



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

-- If this is enabled, the script will try to pull the track/envelope that is under
-- the mouse cursor to the center of the screen while zooming.
shouldCenterVertically = false

-- If this is enabled, the script will zoom the master track (if visible in the TCP)
-- with the rest of the other tracks.
zoomMasterWithOtherTracks = true

-- These are the minimum heights of standard envelopes and the master track.
-- Change these if you need to, but I am not aware of any reason to do so.
-- Changing these to the wrong value will cause unintended scrolling while zooming.
minimumEnvelopeHeight = 24
minimumMasterHeight = 74