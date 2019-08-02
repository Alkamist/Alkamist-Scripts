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

-- If this setting is true, a large padding track will be made at the bottom
-- of the track list to smooth out graphical glitches when zooming in. It will
-- clean up the padding track after the script is done running, unless the script
-- crashes.
usePaddingTrack = true

-- Change this if you want to use action-based vertical zoom in the main view
-- vs. setting the track height directly.
useActionBasedVerticalZoom = false

-- If this is enabled, along with "usePreciseMainViewHorizontalPositionTracking",
-- the script will try to pull the point in time the mouse is zooming to toward
-- the center of the arrange view.
shouldCenterHorizontally = true

-- This setting will set the centerpoint that "shouldCenterHorizontally" pulls
-- to. 0.5 means the center of the arrange view. Change this if the current centerpoint
-- doesn't feel right. Set between 0 and 1.
horizontalCenterPosition = 0.5

-- Change this to determine how fast "shouldCenterHorizontally" will center the view
-- as you zoom. Set to nil to for infinite speed.
horizontalDragCenterSpeed = 10.0

-- Change this to determine how fast "shouldCenterHorizontally" will automatically center
-- the view. Set to nil to for infinite speed.
horizontalAutoCenterSpeed = 30.0

-- If this is enabled, the script will try to pull the track/envelope that is under
-- the mouse cursor to the center of the screen while zooming.
shouldCenterVertically = true

-- This setting will set the centerpoint that "shouldCenterVertically" pulls
-- to. 0.5 means the center of the arrange view. Change this if the current centerpoint
-- doesn't feel right. Set between 0 and 1.
verticalCenterPosition = 0.5

-- Change this to determine how fast "shouldCenterHorizontally" will center the view
-- as you zoom. Set to nil to for infinite speed.
verticalDragCenterSpeed = 10.0

-- Change this to determine how fast "shouldCenterHorizontally" will automatically center
-- the view. Set to nil to for infinite speed.
verticalAutoCenterSpeed = 30.0

-- If this is enabled, the script will zoom the master track (if visible in the TCP)
-- with the rest of the other tracks.
zoomMasterWithOtherTracks = true

-- These are the minimum heights of standard envelopes and the master track.
-- Change these if you need to, but I am not aware of any reason to do so.
-- Changing these to the wrong value will cause unintended scrolling while zooming.
minimumEnvelopeHeight = 24
minimumMasterHeight = 74