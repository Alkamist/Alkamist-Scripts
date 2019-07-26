-- @description Zoom Tool
-- @version 1.1
-- @author Alkamist
-- @donate https://paypal.me/CoreyLehmanMusic
-- @about
--   This script will activate a zoom tool similar to what is used in Melodyne.

-- Change these sensitivities to change the feel of the zoom tool.
local xSensitivity = 0.1
local ySensitivity = 0.1

-- Whether or not to use actions to zoom in the main view, or zoom by changing
-- track height directly.
local useActionBasedVerticalZoom = true

local VKLow, VKHi = 8, 0xFE -- Range of virtual key codes to check for key presses.
local VKState0 = string.rep("\0", VKHi - VKLow + 1)

local startTime = 0
local thisCycleTime = 0

local mouseState = nil
local keyState = nil

local initialMousePos = {}
local currentMousePos = {}

local mainWindow = reaper.GetMainHwnd()
local trackWindow = reaper.JS_Window_FindChildByID(mainWindow, 1000)
local trackHeightFactor = 20.0



function msg(m)
  reaper.ShowConsoleMsg(tostring(m).."\n")
end

function reaperCMD(id)
    if type(id) == "string" then
        reaper.Main_OnCommand(reaper.NamedCommandLookup(id), 0)
    else
        reaper.Main_OnCommand(id, 0)
    end
end

function round(number)
    return math.floor(number + 0.5)
end

function reaperMIDICMD(id)
    if type(id) == "string" then
        reaper.MIDIEditor_LastFocused_OnCommand(reaper.NamedCommandLookup(id), 0)
    else
        reaper.MIDIEditor_LastFocused_OnCommand(id, 0)
    end
end

function scriptShouldStop()
    local prevCycleTime = thisCycleTime or startTime
    thisCycleTime = reaper.time_precise()

    local prevKeyState = keyState
    keyState = reaper.JS_VKeys_GetState(startTime - 0.5):sub(VKLow, VKHi)

    -- All keys are released.
    if keyState ~= prevKeyState and keyState == VKState0 then
        return true
    end

    -- Any keys were pressed.
    local keyDown = reaper.JS_VKeys_GetDown(prevCycleTime):sub(VKLow, VKHi)
    if keyDown ~= prevKeyState and keyDown ~= VKState0 then
        local p = 0
        ::checkNextKeyDown:: do
            p = keyDown:find("\1", p + 1)
            if p then
                if prevKeyState:byte(p) == 0 then
                    return true
                else
                    goto checkNextKeyDown
                end
            end
        end
    end

    -- Mouse was clicked.
    local previousMouseState = mouseState or 0xFF
    mouseState = reaper.JS_Mouse_GetState(0xFF)
    if mouseState > previousMouseState then
        return true
    end

    return false
end

function trackIsValid(track)
    local trackExists = reaper.ValidatePtr(track, "MediaTrack*")
    return track ~= nil and trackExists
end

local mainViewOrigMousePos = {}
local initallyVisibleTracks = {}
local initialTrackHeights = {}
function initializeMainViewVerticalZoom()
    local trackIndex = 1
    for i = 1, reaper.CountTracks(0) do
        local currentTrack = reaper.GetTrack(0, i - 1)

        initialTrackHeights[i] = reaper.GetMediaTrackInfo_Value(currentTrack, "I_WNDH")

        if reaper.IsTrackVisible(currentTrack, false) then
            if trackIsValid(currentTrack) then
                initallyVisibleTracks[trackIndex] = currentTrack

                trackIndex = trackIndex + 1
            end
        end
    end

    mainViewOrigMousePos.x, mainViewOrigMousePos.y = reaper.JS_Window_ScreenToClient(trackWindow, initialMousePos.x, initialMousePos.y)
end

local windowType = nil
local midiWindow = nil
local midiTake = nil
local noteIsSelected = {}
function init()
    startTime = reaper.time_precise()
    thisCycleTime = startTime

    reaper.atexit(atExit)

    -- Load REAPER's native "zoom" cursor
    reaper.JS_Mouse_SetCursor(reaper.JS_Mouse_LoadCursor(1009))

    -- Intercept keyboard input.
    reaper.JS_VKeys_Intercept(-1, 1)

    -- Initialize mouse and keyboard states.
    mouseState = reaper.JS_Mouse_GetState(0xFF)
    keyState = reaper.JS_VKeys_GetState(-2):sub(VKLow, VKHi)

    initialMousePos.x, initialMousePos.y = reaper.GetMousePosition()

    -- Find out what kind of window is under the mouse and focus it.
    windowUnderMouse = reaper.JS_Window_FromPoint(initialMousePos.x, initialMousePos.y)
    if windowUnderMouse then
        -- Prevent REAPER from changing cursor back, by intercepting "SETCURSOR" messages
        reaper.JS_WindowMessage_Intercept(windowUnderMouse, "WM_SETCURSOR", false)

        parentWindow = reaper.JS_Window_GetParent(windowUnderMouse)
        if parentWindow then
            -- Window under mouse is a MIDI editor.
            if windowUnderMouse == reaper.JS_Window_FindChildByID(parentWindow, 1001) then
                reaper.JS_Window_SetFocus(windowUnderMouse)
                windowType = "midi"

                -- Simulate a mouse left click in the MIDI editor to set the pitch cursor, since
                -- the vertical zoom seems to follow where the pitch cursor is. Restore the old note
                -- selection in case any MIDI notes were selected.
                midiWindow = parentWindow
                midiTake = reaper.MIDIEditor_GetTake(midiWindow)
                local _, numMIDINotes = reaper.MIDI_CountEvts(midiTake)

                -- Save the current selection of MIDI notes.
                for i = 1, numMIDINotes do
                    _, noteIsSelected[i] = reaper.MIDI_GetNote(midiTake, i - 1)
                end

                -- Simulate the mouse click.
                midiMouseX, midiMouseY = reaper.JS_Window_ScreenToClient(windowUnderMouse, initialMousePos.x, initialMousePos.y)
                reaper.JS_WindowMessage_Post(windowUnderMouse, "WM_LBUTTONDOWN", 0, 0, midiMouseX, midiMouseY)
                reaper.JS_WindowMessage_Post(windowUnderMouse, "WM_LBUTTONUP", 0, 0, midiMouseX, midiMouseY)

                -- Check if any notes were accidentally created and delete them.
                local _, newMIDINoteCount = reaper.MIDI_CountEvts(midiTake)
                if newMIDINoteCount > numMIDINotes then
                    reaperMIDICMD(40002) -- delete notes
                end

                -- The mouse button clicks are asynchronously handled, so we need restore the MIDI
                -- selection later on in the code after the mouse up event happens.

            -- Window under mouse is the main editor.
            elseif parentWindow == reaper.GetMainHwnd() then
                reaper.JS_Window_SetFocus(windowUnderMouse)
                windowType = "main"

                if not useActionBasedVerticalZoom then
                    initializeMainViewVerticalZoom()
                end
            end
        end
    end

    reaper.defer(update)
end

local midiSelectionRestored = false
function restoreMIDISelection()
    -- Restore the previous selection of MIDI notes.
    for i = 1, #noteIsSelected do
        reaper.MIDI_SetNote(midiTake, i - 1, noteIsSelected[i], nil, nil, nil, nil, nil, nil, true)

        local _, currentNoteIsSelected = reaper.MIDI_GetNote(midiTake, i - 1)
        midiSelectionRestored = noteIsSelected[i] == currentNoteIsSelected
    end
    reaper.MIDI_Sort(midiTake)
end

function zoomInVertically()
    if windowType == "main" then
        reaperCMD(40111) -- zoom in vertical
    elseif windowType == "midi" then
        reaperMIDICMD(40111) -- zoom in vertical
    end
end

function zoomOutVertically()
    if windowType == "main" then
        reaperCMD(40112) -- zoom out vertical
    elseif windowType == "midi" then
        reaperMIDICMD(40112) -- zoom out vertical
    end
end

function getEnvelopeHeight(envelope, trackHeight)
    local _, envelopeChunk = reaper.GetEnvelopeStateChunk(envelope, "", false)

    local envelopeVisibilityChunk = envelopeChunk:match("VIS (%d%s%d)")
    local envelopeIsVisible = envelopeVisibilityChunk:sub(1, 1)
    local envelopeIsInOwnLane = envelopeVisibilityChunk:sub(3, 3)

    local envelopeHeight = tonumber(envelopeChunk:match("LANEHEIGHT (%d+)"))

    -- Need to work on getting the actual track height
    if envelopeHeight == 0 and envelopeIsInOwnLane and envelopeIsVisible then
        envelopeHeight = floor(trackHeight / (1.0 + 1.0 / 3.0))
    end

    if (not envelopeIsInOwnLane) or (not envelopeIsVisible) then
        envelopeHeight = 0
    end

    return envelopeHeight
end

function getTCPTracksOnScreen()
    local tracksOnScreen = {}

    local trackPixelStart = 0
    local _, scrollPos, scrollPageSize, scrollMin, scrollMax, scrollTrackPos = reaper.JS_Window_GetScrollInfo(trackWindow, "VERT")
    local _, windowWidth, windowHeight = reaper.JS_Window_GetClientSize(trackWindow)

    local trackIndex = 1
    for i = 1, #initallyVisibleTracks do
        local currentTrack = initallyVisibleTracks[i]
        trackPixelEnd = trackPixelStart + reaper.GetMediaTrackInfo_Value(currentTrack, "I_WNDH")

        local screenStart = scrollPos
        local screenEnd = scrollPos + windowHeight

        local trackIsCompletelyOnScreen = trackPixelStart >= screenStart and trackPixelEnd < screenEnd
        local trackStartsOffScreenButEndsOnScreen = trackPixelStart < screenStart and trackPixelEnd >= screenStart
        local trackStartsOnScreenButEndsOffScreen = trackPixelStart < screenEnd and trackPixelEnd >= screenEnd

        if trackIsCompletelyOnScreen or trackStartsOffScreenButEndsOnScreen or trackStartsOnScreenButEndsOffScreen then
            tracksOnScreen[trackIndex] = currentTrack
            trackIndex = trackIndex + 1
        end

        trackPixelStart = trackPixelEnd
    end

    return tracksOnScreen
end

function setTrackZoom(track, zoom)
    local currentTrackNumber = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    local currentHeight = initialTrackHeights[currentTrackNumber]

    --for j = 1, reaper.CountTrackEnvelopes(track) do
    --    local currentEnvelope = reaper.GetTrackEnvelope(track, j - 1)
        --currentHeight = currentHeight - getEnvelopeHeight(currentEnvelope)
        --getEnvelopeHeight(currentEnvelope, currentHeight)
    --end

    local trackHeight = currentHeight + zoom * trackHeightFactor
    local trackHeight = math.max(trackHeight, 1)

    reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", trackHeight);
end

function adjustAllTrackHeightsToZoom(zoom)
    reaper.PreventUIRefresh(1)

    for i = 1, #initallyVisibleTracks do
        local currentTrack = initallyVisibleTracks[i]
        setTrackZoom(currentTrack, zoom)
    end
    reaper.TrackList_AdjustWindows(false)

    -- Some tracks are already scaled when they fall off the screen. You need to take that into account.
    -- Maybe loop through and compare their old heights to their new ones and accumulate the values.
    -- Do the same for the new track that pops on screen and screws up scrolling.
    local tracksOnScreen = getTCPTracksOnScreen()
    local firstTrackOnScreenNumber = reaper.GetMediaTrackInfo_Value(tracksOnScreen[1], "IP_TRACKNUMBER")
    local numberOfTracksAboveScreen = firstTrackOnScreenNumber - 1

    local _, scrollPos, scrollPageSize, scrollMin, scrollMax, scrollTrackPos = reaper.JS_Window_GetScrollInfo(trackWindow, "VERT")

    local scrollCorrection = zoom * numberOfTracksAboveScreen * trackHeightFactor
    local newScrollPos = math.max(round(scrollPos + scrollCorrection), 0)
    reaper.JS_Window_SetScrollPos(trackWindow, "VERT", newScrollPos)

    reaper.PreventUIRefresh(-1)
end

function adjustMainViewVerticalZoom(relative, zoom)
    reaper.PreventUIRefresh(1)

    local tracksOnScreen = getTCPTracksOnScreen()

    -- Some envelopes will change height based on whether or not their height was
    -- manually set. We need to account for them as we find them.
    local numZoomingEnvelopes = 0
    for i = 1, #tracksOnScreen do
        local currentTrack = tracksOnScreen[i]
        setTrackZoom(currentTrack, zoom)
    end
    reaper.TrackList_AdjustWindows(false)

    local _, scrollPos, scrollPageSize, scrollMin, scrollMax, scrollTrackPos = reaper.JS_Window_GetScrollInfo(trackWindow, "VERT")
    local _, windowWidth, windowHeight = reaper.JS_Window_GetClientSize(trackWindow)

    local mouseYRatio = mainViewOrigMousePos.y / windowHeight
    local scrollCorrection = relative * #tracksOnScreen * trackHeightFactor * mouseYRatio
    local newScrollPos = math.max(round(scrollPos + scrollCorrection), 0)
    reaper.JS_Window_SetScrollPos(trackWindow, "VERT", newScrollPos)

    reaper.PreventUIRefresh(-1)
end

local previousXAccumAdjust = 0
local previousYAccumAdjust = 0
local xZoomTick = 1
local yZoomTick = 1
local xAccumAdjust = 0
local yAccumAdjust = 0
function update()
    if scriptShouldStop() then return 0 end

    currentMousePos.x, currentMousePos.y = reaper.GetMousePosition()

    -- ==================== HORIZONTAL ZOOM ====================

    local xAdjust = (currentMousePos.x - initialMousePos.x) * xSensitivity
    xAccumAdjust = xAccumAdjust + xAdjust

    -- Handle horizontal zoom in main view.
    if windowType == "main" then
        reaper.adjustZoom(xAdjust, 0, true, -1)

    -- I can't find a way to adjust the MIDI editor's zoom via the API,
    -- so I have to do it with Reaper actions.
    elseif windowType == "midi" then
        -- Keep checking if we need to restore the original MIDI note selection.
        if not midiSelectionRestored then
            restoreMIDISelection()
        end

        local tickLowValue = xZoomTick * math.floor(xAccumAdjust / xZoomTick)
        local tickHighValue = xZoomTick * math.ceil(xAccumAdjust / xZoomTick)

        if previousXAccumAdjust < tickLowValue then
            local overflow = math.ceil((tickLowValue - previousXAccumAdjust) / yZoomTick)
            for i = 1, overflow do
                reaperMIDICMD(1012) -- zoom in horizontal
                reaper.JS_Mouse_SetPosition(initialMousePos.x, initialMousePos.y)
            end

        elseif previousXAccumAdjust > tickHighValue then
            local overflow = math.ceil((previousXAccumAdjust - tickHighValue) / yZoomTick)
            for i = 1, overflow do
                reaperMIDICMD(1011) -- zoom out horizontal
                reaper.JS_Mouse_SetPosition(initialMousePos.x, initialMousePos.y)
            end
        end
    end

    -- ==================== VERTICAL ZOOM ====================

    local yAdjust = (currentMousePos.y - initialMousePos.y) * ySensitivity
    yAccumAdjust = yAccumAdjust + yAdjust

    if useActionBasedVerticalZoom or windowType == "midi" then
        local tickLowValue = yZoomTick * math.floor(yAccumAdjust / yZoomTick)
        local tickHighValue = yZoomTick * math.ceil(yAccumAdjust / yZoomTick)

        if previousYAccumAdjust < tickLowValue then
            local overflow = math.ceil((tickLowValue - previousYAccumAdjust) / yZoomTick)
            for i = 1, overflow do
                zoomInVertically()
                reaper.JS_Mouse_SetPosition(initialMousePos.x, initialMousePos.y)
            end

        elseif previousYAccumAdjust > tickHighValue then
            local overflow = math.ceil((previousYAccumAdjust - tickHighValue) / yZoomTick)
            for i = 1, overflow do
                zoomOutVertically()
                reaper.JS_Mouse_SetPosition(initialMousePos.x, initialMousePos.y)
            end
        end
    else
        if yAdjust > 0 or yAdjust < 0 then
            adjustMainViewVerticalZoom(yAdjust, yAccumAdjust)
        end
    end

    -- =======================================================

    previousXAccumAdjust = xAccumAdjust
    previousYAccumAdjust = yAccumAdjust

    reaper.JS_Mouse_SetPosition(initialMousePos.x, initialMousePos.y)

    reaper.defer(update)
end

function atExit()
    if (not useActionBasedVerticalZoom) and windowType == "main" then
        adjustAllTrackHeightsToZoom(yAccumAdjust)
    end

    -- Release any intercepts.
    reaper.JS_WindowMessage_ReleaseAll()

    -- Stop intercepting keyboard input.
    reaper.JS_VKeys_Intercept(-1, -1)
end

init()