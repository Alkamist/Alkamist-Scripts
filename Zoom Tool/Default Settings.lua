--[[

DO NOT CHANGE THIS FILE. INSTEAD, COPY THIS FILE AS:

"Scripts\Alkamist Scripts\Zoom Tool\User Settings.lua"

AND CHANGE THE SETTINGS THERE.

]]--



-- Change these sensitivities to change the feel of the zoom tool.
xSensitivity = 0.1
ySensitivity = 0.1

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