-- @description Zoom Tool
-- @version 1.5.1
-- @author Alkamist
-- @donate https://paypal.me/CoreyLehmanMusic
-- @about
--   This script will activate a zoom tool similar to what is used in Melodyne.

-- Change these sensitivities to change the feel of the zoom tool.
local xSensitivity = 0.1
local ySensitivity = 0.1

-- Change this if you want to use action-based vertical zoom in the main view
-- vs. setting the track height directly.
local useActionBasedVerticalZoom = false

-- Change this to the minimum track height of your Reaper skin. This only matters
-- if you are zooming by setting the track height directly.
local minTrackHeight = 25
local minimumEnvelopeHeight = 24

local VKLow, VKHi = 8, 0xFE -- Range of virtual key codes to check for key presses.
local VKState0 = string.rep("\0", VKHi - VKLow + 1)

local startTime = 0
local thisCycleTime = 0

local mouseState = nil
local keyState = nil

local initialMousePos = {}
local currentMousePos = {}

local mainWindow = reaper.GetMainHwnd()
local arrangeWindow = reaper.JS_Window_FindChildByID(mainWindow, 1000)
local trackYZoomFactor = 0.2

local masterTrack = reaper.GetMasterTrack(0)



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

local uiShouldRefresh = true
function setUIRefresh(state)
    -- Enable UI refresh.
    if state and not uiShouldRefresh then
        reaper.PreventUIRefresh(-1)

    -- Disable UI refresh.
    elseif not state and uiShouldRefresh then
        reaper.PreventUIRefresh(1)
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

function getTrackNumber(track)
    local trackNumber = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")

    if trackNumber == -1 then
        trackNumber = 0
    elseif trackNumber == 0 then
        trackNumber = -1
    end

    return trackNumber
end

function getTrackHeight(track)
    local trackViewWindow = nil

    local _, _, arrangeTop = reaper.JS_Window_GetRect(arrangeWindow)
    local window = reaper.JS_Window_GetRelated(arrangeWindow, "NEXT")
    while window do
        local _, _, top = reaper.JS_Window_GetRect(window)

        if top == arrangeTop then
            trackViewWindow = reaper.JS_Window_GetRelated(window, "CHILD")
        end

        window = reaper.JS_Window_GetRelated(window, "NEXT")
    end

    local specificTrackWindow = reaper.JS_Window_GetRelated(trackViewWindow, "CHILD")

    local outputHeight = 0
    if specificTrackWindow then
        local trackPointer = reaper.JS_Window_GetLongPtr(specificTrackWindow, "USERDATA")

        while trackPointer ~= track and trackPointer ~= nil do
            specificTrackWindow = reaper.JS_Window_GetRelated(specificTrackWindow, "NEXT")
            trackPointer = reaper.JS_Window_GetLongPtr(specificTrackWindow, "USERDATA")
        end

        local _, _, top, _, bottom = reaper.JS_Window_GetRect(specificTrackWindow)

        if trackIsValid(trackPointer) then
            outputHeight = bottom - top
        end
    end

    return outputHeight
end

function masterIsVisibleInTCP()
    local visibility = reaper.GetMasterTrackVisibility()
    return visibility == 1 or visibility == 3
end

local mainViewOrigMouseLocation = {}
local initallyVisibleTracks = {}
local mainViewOrigMouseClientLocation = {}
function initializeMainViewVerticalZoom()
    local _, scrollPos, scrollPageSize, scrollMin, scrollMax, scrollTrackPos = reaper.JS_Window_GetScrollInfo(arrangeWindow, "VERT")
    local mousePixelYPos = scrollPos + mainViewOrigMouseClientLocation.y
    local mousePixelYPosRecorded = false
    local currentTrackPixelEnd = 0
    local lastVisibleTrackNumber = 0

    for i = 0, reaper.CountTracks(0) do
        local currentTrack = nil

        if i == 0 then
            if masterIsVisibleInTCP() then
                currentTrack = masterTrack
            end
        else
            currentTrack = reaper.GetTrack(0, i - 1)
        end

        if trackIsValid(currentTrack) then
            if reaper.IsTrackVisible(currentTrack, false) then
                lastVisibleTrackNumber = i

                initallyVisibleTracks[i] = {}
                initallyVisibleTracks[i].track = currentTrack

                local currentLaneHeight = reaper.GetMediaTrackInfo_Value(currentTrack, "I_WNDH")
                initallyVisibleTracks[i].currentLaneHeight = currentLaneHeight

                local currentTrackHeight = getTrackHeight(currentTrack)
                initallyVisibleTracks[i].initialTrackHeight = currentTrackHeight

                initallyVisibleTracks[i].zoomWasSetOnce = false

                currentTrackPixelEnd = currentTrackPixelEnd + currentLaneHeight

                if i == 0 then
                    currentTrackPixelEnd = currentTrackPixelEnd + 5
                end

                if currentTrackPixelEnd > mousePixelYPos and not mousePixelYPosRecorded then
                    mainViewOrigMouseLocation.trackNumber = i
                    mainViewOrigMouseLocation.trackRatio = (mousePixelYPos - currentTrackPixelEnd + currentLaneHeight) / currentLaneHeight
                    mousePixelYPosRecorded = true
                end

                for j = 1, reaper.CountTrackEnvelopes(currentTrack) do
                    local currentEnvelope = reaper.GetTrackEnvelope(currentTrack, j - 1)
                    initallyVisibleTracks[i][currentEnvelope] = {}
                    initallyVisibleTracks[i][currentEnvelope].initialHeight = getEnvelopeHeight(currentEnvelope, currentTrackHeight)
                end
            end
        end
    end

    if not mousePixelYPosRecorded then
        mainViewOrigMouseLocation.trackNumber = lastVisibleTrackNumber
        mainViewOrigMouseLocation.trackRatio = 1.0
    end
end

local mainViewMouseXSeconds = 0
function initializeMainViewHorizontalZoom()
    local _, scrollPos, scrollPageSize, scrollMin, scrollMax, scrollTrackPos = reaper.JS_Window_GetScrollInfo(arrangeWindow, "HORZ")

    mainViewMouseXSeconds = (scrollPos + mainViewOrigMouseClientLocation.x) / reaper.GetHZoomLevel()
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

                mainViewOrigMouseClientLocation.x, mainViewOrigMouseClientLocation.y = reaper.JS_Window_ScreenToClient(arrangeWindow, initialMousePos.x, initialMousePos.y)

                initializeMainViewHorizontalZoom()

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

function getEnvelopeStats(envelope)
    local _, envelopeChunk = reaper.GetEnvelopeStateChunk(envelope, "", false)

    local envelopeVisibilityChunk = envelopeChunk:match("VIS (%d%s%d)")
    local envelopeIsVisible = tonumber(envelopeVisibilityChunk:sub(1, 1)) > 0
    local envelopeIsInOwnLane = tonumber(envelopeVisibilityChunk:sub(3, 3)) > 0

    local envelopeHeight = tonumber(envelopeChunk:match("LANEHEIGHT (%d+)"))

    return envelopeHeight, envelopeIsVisible, envelopeIsInOwnLane
end

function getEnvelopeHeight(envelope, trackHeight)
    local envelopeHeight, envelopeIsVisible, envelopeIsInOwnLane = getEnvelopeStats(envelope)

    local envelopeHeightIsBasedOnTrack = envelopeHeight == 0 and envelopeIsVisible and envelopeIsInOwnLane

    if envelopeHeightIsBasedOnTrack then
        envelopeHeight = math.max(math.floor(trackHeight * 0.75), minimumEnvelopeHeight)
    end

    if (not envelopeIsInOwnLane) or (not envelopeIsVisible) then
        envelopeHeight = 0
    end

    return envelopeHeight, envelopeHeightIsBasedOnTrack
end

-- Unfortunately setting envelope height manually is extremely slow and will lag the script.
-- Until I find a faster way to set it, I will have this disabled.
function zoomEnvelope(envelope, zoom, initialHeight)
    local _, envelopeState = reaper.GetEnvelopeStateChunk(envelope, "", false)

    local _, heightIsBasedOnTrack = getEnvelopeHeight(envelope, 1)

    if not heightIsBasedOnTrack then
        newHeight = round(initialHeight * zoom)
        reaper.SetEnvelopeStateChunk(envelope, envelopeState:gsub("LANEHEIGHT %d+", "LANEHEIGHT " .. tostring(newHeight)), false)
    end
end

function setTrackZoom(track, zoom)
    local _, windowWidth, windowHeight = reaper.JS_Window_GetClientSize(arrangeWindow)

    local currentTrackNumber = getTrackNumber(track)

    local trackHeight = initallyVisibleTracks[currentTrackNumber].initialTrackHeight * zoom

    if currentTrackNumber == 0 then
        local minMasterHeight = 74
        trackHeight = math.max(trackHeight, minMasterHeight)
    else
        trackHeight = math.max(trackHeight, minTrackHeight)
    end

    trackHeight = math.min(trackHeight, windowHeight * 1.3333333333333)

    local cumulativeEnvelopeHeight = 0
    for i = 1, reaper.CountTrackEnvelopes(track) do
        local currentEnvelope = reaper.GetTrackEnvelope(track, i - 1)

        --zoomEnvelope(currentEnvelope, zoom, initallyVisibleTracks[currentTrackNumber][currentEnvelope].initialHeight)
        local envelopeHeight = getEnvelopeHeight(currentEnvelope, trackHeight)
        cumulativeEnvelopeHeight = cumulativeEnvelopeHeight + envelopeHeight
    end

    reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", trackHeight);

    initallyVisibleTracks[currentTrackNumber].currentLaneHeight = reaper.GetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE") + cumulativeEnvelopeHeight
end

function setMainViewVerticalScroll(position)
    local newPosition = math.max(round(position), 0)
    reaper.JS_Window_SetScrollPos(arrangeWindow, "VERT", newPosition)
end

function correctMainViewVerticalScroll()
    if #initallyVisibleTracks > 0 or masterIsVisibleInTCP() then
        local correctScrollPosition = 0
        local newMouseOverTrackHeight = initallyVisibleTracks[mainViewOrigMouseLocation.trackNumber].currentLaneHeight

        if masterIsVisibleInTCP() then
            correctScrollPosition = correctScrollPosition + 5
        end

        local correctScrollMouseOffsetPixels = mainViewOrigMouseLocation.trackRatio * newMouseOverTrackHeight

        for trackNumber, value in pairs(initallyVisibleTracks) do
            if trackNumber < mainViewOrigMouseLocation.trackNumber then
                correctScrollPosition = correctScrollPosition + value.currentLaneHeight
            end
        end

        correctScrollPosition = correctScrollPosition + correctScrollMouseOffsetPixels - mainViewOrigMouseClientLocation.y

        local _, scrollPos, scrollPageSize, scrollMin, scrollMax, scrollTrackPos = reaper.JS_Window_GetScrollInfo(arrangeWindow, "VERT")

        -- If you zoom too far then you unfortunately have to allow for the UI to update,
        -- otherwise you will end up hitting the end of the tracklist and scrolling to
        -- the wrong place.
        if correctScrollPosition + scrollPageSize > scrollMax then
            setUIRefresh(true)
        end

        setMainViewVerticalScroll(correctScrollPosition)
    end
end

function setMainViewVerticalZoom(zoom)
    setUIRefresh(false)

    if masterIsVisibleInTCP() then
        setTrackZoom(masterTrack, zoom)
    end

    for trackNumber, value in pairs(initallyVisibleTracks) do
        setTrackZoom(value.track, zoom)
    end
    reaper.TrackList_AdjustWindows(false)

    correctMainViewVerticalScroll()

    setUIRefresh(true)
end

function setMainViewHorizontalScroll(position)
    local newPosition = math.max(round(position), 0)
    reaper.JS_Window_SetScrollPos(arrangeWindow, "HORZ", newPosition)
end

function correctMainViewHorizontalScroll()
    local _, scrollPos, scrollPageSize, scrollMin, scrollMax, scrollTrackPos = reaper.JS_Window_GetScrollInfo(arrangeWindow, "HORZ")

    local correctScrollPosition = mainViewMouseXSeconds * reaper.GetHZoomLevel() - mainViewOrigMouseClientLocation.x

    setMainViewHorizontalScroll(correctScrollPosition)
end

function adjustMainViewHorizontalZoom(zoom)
    reaper.adjustZoom(zoom, 0, true, -1)
    correctMainViewHorizontalScroll()
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
        adjustMainViewHorizontalZoom(xAdjust)

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
        setMainViewVerticalZoom(2.0 ^ (yAccumAdjust * trackYZoomFactor))
    end

    -- =======================================================

    previousXAccumAdjust = xAccumAdjust
    previousYAccumAdjust = yAccumAdjust

    reaper.JS_Mouse_SetPosition(initialMousePos.x, initialMousePos.y)

    reaper.defer(update)
end

function atExit()
    -- Release any intercepts.
    reaper.JS_WindowMessage_ReleaseAll()

    -- Stop intercepting keyboard input.
    reaper.JS_VKeys_Intercept(-1, -1)
end

init()