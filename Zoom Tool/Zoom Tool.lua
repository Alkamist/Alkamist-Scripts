-- @description Zoom Tool
-- @version 1.5.6
-- @author Alkamist
-- @donate https://paypal.me/CoreyLehmanMusic
-- @about
--   This script will activate a zoom tool similar to what is used in Melodyne.
--   Be sure to install the default settings file into:
--
--   "Scripts\Alkamist Scripts\Zoom Tool\Zoom Tool Default Settings.lua"
--
--   You can copy that file into the same folder and call it "Zool Tool User Settings.lua"
--   and change the settings in there. That way, your settings are not overwritten
--   when updating.
-- @changelog
--   + Fixed really bad bug with UI refresh.
--   + Added a system that creates a padding track for smoother zooming.

package.path = reaper.GetResourcePath().. package.config:sub(1,1) .. '?.lua;' .. package.path

-- This loads the default settings to be used in the script.
require 'Scripts.Alkamist Scripts.Zoom Tool.Zoom Tool Default Settings'

-- This will overwrite the default settings with your settings from the file:
-- "Scripts\Alkamist Scripts\Zoom Tool\Zoom Tool User Settings.lua"
pcall(require, 'Scripts.Alkamist Scripts.Zoom Tool.Zoom Tool User Settings')



-- A rescale of sensitivity for aesthetic purposes.
xSensitivity = xSensitivity * 0.1
ySensitivity = ySensitivity * 0.1

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
local arrangeYZoomFactor = 0.3
local arrangeXZoomFactor = 1.3

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

local uiEnabled = true
function setUIRefresh(enable)
    -- Enable UI refresh.
    if enable then
        if not uiEnabled then
            reaper.PreventUIRefresh(-1)
            uiEnabled = true
        end

    -- Disable UI refresh.
    else
        if uiEnabled then
            reaper.PreventUIRefresh(1)
            uiEnabled = false
        end
    end
end

local minTrackHeight = 0
function getMinimumTrackHeight()
    local _, currentTheme = reaper.get_config_var_string("lastthemefn5")

    local previousTheme = reaper.GetExtState("Previous stats since Alkamist: Zoom Tool run", "Theme")
    local minimumTrackHeight = tonumber(reaper.GetExtState("Previous stats since Alkamist: Zoom Tool run", "Minimum Track Height"))

    if currentTheme ~= previousTheme then
        local prevvzoom2 = reaper.SNM_GetIntConfigVar("vzoom2", -1)
        reaper.SNM_SetIntConfigVar("vzoom2", 0)

        local lastTrackNumber = reaper.GetNumTracks()

        reaper.InsertTrackAtIndex(lastTrackNumber, false)

        local tempTrack = reaper.GetTrack(0, lastTrackNumber)
        reaper.SetMediaTrackInfo_Value(tempTrack, "I_HEIGHTOVERRIDE", 1)

        minimumTrackHeight = reaper.GetMediaTrackInfo_Value(tempTrack, "I_WNDH")

        reaper.DeleteTrack(tempTrack)

        reaper.SNM_SetIntConfigVar("vzoom2", prevvzoom2)

        reaper.SetExtState("Previous stats since Alkamist: Zoom Tool run", "Theme", currentTheme, true)
        reaper.SetExtState("Previous stats since Alkamist: Zoom Tool run", "Minimum Track Height", minimumTrackHeight, true)
    end

    return minimumTrackHeight
end

local paddingTrack = nil
local paddingTrackNumber = 0
function createPaddingTrack()
    if paddingTrack == nil then
        paddingTrackNumber = reaper.GetNumTracks()

        reaper.InsertTrackAtIndex(paddingTrackNumber, false)

        paddingTrack = reaper.GetTrack(0, paddingTrackNumber)
        reaper.SetMediaTrackInfo_Value(paddingTrack, "I_HEIGHTOVERRIDE", 20000)
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

local initallyVisibleTracks = {}
local mainViewOrigMouseLocation = {}
local mainViewOrigMouseClientLocation = {}
function initializeMainViewVerticalZoom()
    minTrackHeight = getMinimumTrackHeight()

    local _, scrollPos, scrollPageSize, scrollMin, scrollMax, scrollTrackPos = reaper.JS_Window_GetScrollInfo(arrangeWindow, "VERT")
    local mousePixelYPos = scrollPos + mainViewOrigMouseClientLocation.y
    local mousePixelYPosRecorded = false
    local currentLanePixelEnd = 0
    local currentZonePixelEnd = 0
    local lastVisibleTrack = nil
    local lastVisibleTrackNumber = 0
    local lastVisibleEnvelope = nil
    local lastVisibleEnvelopeNumber = 0

    for i = 0, reaper.GetNumTracks() do
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
                lastVisibleTrack = currentTrack
                lastVisibleTrackNumber = i

                initallyVisibleTracks[i] = {}
                initallyVisibleTracks[i].track = currentTrack

                local currentLaneHeight = reaper.GetMediaTrackInfo_Value(currentTrack, "I_WNDH")
                initallyVisibleTracks[i].currentLaneHeight = currentLaneHeight

                local currentTrackHeight = getTrackHeight(currentTrack)
                initallyVisibleTracks[i].initialTrackHeight = currentTrackHeight

                initallyVisibleTracks[i].zoomWasSetOnce = false

                currentLanePixelEnd = currentLanePixelEnd + currentLaneHeight
                currentZonePixelEnd = currentZonePixelEnd + currentTrackHeight

                -- Record information about the initial vertical position of the mouse in arrange.
                -- If envelopeNumber is 0 then the mouse is on a track. zoneRatio is the normalized
                -- position of the mouse over the track or envelope (0.0 to 1.0).
                if currentZonePixelEnd > mousePixelYPos and not mousePixelYPosRecorded then
                    mainViewOrigMouseLocation.track = currentTrack
                    mainViewOrigMouseLocation.trackNumber = i
                    mainViewOrigMouseLocation.envelope = nil
                    mainViewOrigMouseLocation.envelopeNumber = 0
                    mainViewOrigMouseLocation.zoneRatio = (mousePixelYPos - currentZonePixelEnd + currentTrackHeight) / currentTrackHeight
                    mainViewOrigMouseLocation.trackRatio = mainViewOrigMouseLocation.zoneRatio
                    mainViewOrigMouseLocation.fullEnvelopeLaneRatio = 0.0
                    mousePixelYPosRecorded = true
                end

                -- envelopeNumber corresponds to the envelope the mouse is over.
                for j = 1, reaper.CountTrackEnvelopes(currentTrack) do
                    local currentEnvelope = reaper.GetTrackEnvelope(currentTrack, j - 1)
                    lastVisibleEnvelope = currentEnvelope
                    lastVisibleEnvelopeNumber = j

                    initallyVisibleTracks[i][currentEnvelope] = {}

                    local currentEnvelopeHeight, envelopeIsManuallySet = getEnvelopeHeight(currentEnvelope, currentTrackHeight)
                    initallyVisibleTracks[i][currentEnvelope].initialHeight = currentEnvelopeHeight
                    initallyVisibleTracks[i][currentEnvelope].isManuallySet = envelopeIsManuallySet

                    currentZonePixelEnd = currentZonePixelEnd + currentEnvelopeHeight

                    if currentZonePixelEnd > mousePixelYPos and not mousePixelYPosRecorded then
                        mainViewOrigMouseLocation.track = currentTrack
                        mainViewOrigMouseLocation.trackNumber = i
                        mainViewOrigMouseLocation.envelope = currentEnvelope
                        mainViewOrigMouseLocation.envelopeNumber = j
                        mainViewOrigMouseLocation.zoneRatio = (mousePixelYPos - currentZonePixelEnd + currentEnvelopeHeight) / currentEnvelopeHeight
                        mainViewOrigMouseLocation.trackRatio = 1.0
                        local fullEnvelopeLaneHeight = currentLaneHeight - currentTrackHeight
                        mainViewOrigMouseLocation.fullEnvelopeLaneRatio = (mousePixelYPos - currentLanePixelEnd + currentLaneHeight - currentTrackHeight) / fullEnvelopeLaneHeight
                        mousePixelYPosRecorded = true
                    end
                end

                -- The master track has 5 extra pixels of empty space tacked onto the end of it.
                -- We need to account for that.
                if i == 0 then
                    currentZonePixelEnd = currentZonePixelEnd + 5
                    currentLanePixelEnd = currentLanePixelEnd + 5
                end
            end
        end
    end

    -- The mouse is below the last envelope in the track list.
    if not mousePixelYPosRecorded then
        mainViewOrigMouseLocation.track = lastVisibleTrack
        mainViewOrigMouseLocation.trackNumber = lastVisibleTrackNumber
        mainViewOrigMouseLocation.envelope = lastVisibleEnvelope
        mainViewOrigMouseLocation.envelopeNumber = lastVisibleEnvelopeNumber
        mainViewOrigMouseLocation.zoneRatio = 1.0
        mainViewOrigMouseLocation.trackRatio = 1.0
        mainViewOrigMouseLocation.fullEnvelopeLaneRatio = 1.0
        mainViewOrigMouseLocation.needsLongEnvelopeCalc = false
    else
        for i = 1, reaper.CountTrackEnvelopes(mainViewOrigMouseLocation.track) do
            local currentEnvelope = reaper.GetTrackEnvelope(mainViewOrigMouseLocation.track, i - 1)

            if i <= mainViewOrigMouseLocation.envelopeNumber and initallyVisibleTracks[mainViewOrigMouseLocation.trackNumber][currentEnvelope].isManuallySet then
                mainViewOrigMouseLocation.needsLongEnvelopeCalc = true
            end
        end
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
    if envelope then
        local envelopeHeight, envelopeIsVisible, envelopeIsInOwnLane = getEnvelopeStats(envelope)

        local envelopeHeightIsBasedOnTrack = envelopeHeight == 0 and envelopeIsVisible and envelopeIsInOwnLane
        local envelopeHeightIsManuallySet = (not envelopeHeightIsBasedOnTrack) and envelopeIsVisible and envelopeIsInOwnLane

        if envelopeHeightIsBasedOnTrack then
            envelopeHeight = math.max(math.floor(trackHeight * 0.75), minimumEnvelopeHeight)
        end

        if (not envelopeIsInOwnLane) or (not envelopeIsVisible) then
            envelopeHeight = 0
        end

        return envelopeHeight, envelopeHeightIsManuallySet
    end

    return 0, false
end

function setTrackZoom(track, zoom)
    local _, windowWidth, windowHeight = reaper.JS_Window_GetClientSize(arrangeWindow)

    local currentTrackNumber = getTrackNumber(track)

    local trackHeight = round(initallyVisibleTracks[currentTrackNumber].initialTrackHeight * zoom)

    if currentTrackNumber == 0 then
        trackHeight = math.max(trackHeight, minimumMasterHeight)
    else
        trackHeight = math.max(trackHeight, minTrackHeight)
    end

    trackHeight = math.min(trackHeight, windowHeight * 1.3333333333333)

    local cumulativeEnvelopeHeight = 0
    for i = 1, reaper.CountTrackEnvelopes(track) do
        local currentEnvelope = reaper.GetTrackEnvelope(track, i - 1)

        local envelopeHeight = getEnvelopeHeight(currentEnvelope, trackHeight)

        cumulativeEnvelopeHeight = cumulativeEnvelopeHeight + envelopeHeight
    end

    reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", trackHeight)

    initallyVisibleTracks[currentTrackNumber].currentLaneHeight = reaper.GetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE") + cumulativeEnvelopeHeight
end

function setMainViewVerticalScroll(position)
    local newPosition = math.max(round(position), 0)
    reaper.JS_Window_SetScrollPos(arrangeWindow, "VERT", newPosition)
end

function correctMainViewVerticalScroll()
    if #initallyVisibleTracks > 0 or masterIsVisibleInTCP() then
        local _, windowWidth, windowHeight = reaper.JS_Window_GetClientSize(arrangeWindow)

        local correctScrollPosition = 0
        local correctScrollMouseOffsetPixels = 0

        -- Go through all of the tracks before the current mouseover track and add their
        -- full lane heights.
        for trackNumber, value in pairs(initallyVisibleTracks) do
            if trackNumber < mainViewOrigMouseLocation.trackNumber then
                correctScrollPosition = correctScrollPosition + value.currentLaneHeight
            end
        end

        -- You need to run more complicated and thus slower code to calculate the mouse position
        -- if there are any manually set envelopes, since the mouse position can't be calculated
        -- with a broad ratio over the entire window height.
        if mainViewOrigMouseLocation.needsLongEnvelopeCalc then
            local newMouseOverZoneHeight = 0
            local newMouseOverTrackHeight = getTrackHeight(mainViewOrigMouseLocation.track)

            -- The mouse is over a track.
            if mainViewOrigMouseLocation.envelopeNumber < 1 then
                newMouseOverZoneHeight = newMouseOverTrackHeight

            -- The mouse is over an envelope.
            else
                newMouseOverZoneHeight = getEnvelopeHeight(mainViewOrigMouseLocation.envelope, newMouseOverTrackHeight)
                correctScrollPosition = correctScrollPosition + newMouseOverTrackHeight
            end
            correctScrollMouseOffsetPixels = mainViewOrigMouseLocation.zoneRatio * newMouseOverZoneHeight

            -- Go through all of the envelopes and process accordingly.
            for i = 1, reaper.CountTrackEnvelopes(mainViewOrigMouseLocation.track) do
                if i < mainViewOrigMouseLocation.envelopeNumber then
                    local currentEnvelope = reaper.GetTrackEnvelope(mainViewOrigMouseLocation.track, i - 1)

                    local currentEnvelopeHeight = getEnvelopeHeight(currentEnvelope, newMouseOverTrackHeight)
                    correctScrollPosition = correctScrollPosition + currentEnvelopeHeight
                end
            end

        -- Simpler and faster broad calculation.
        else
            local newMouseOverHeight = 0
            local newMouseOverTrackHeight = getTrackHeight(mainViewOrigMouseLocation.track)

            -- The mouse is over a track.
            if mainViewOrigMouseLocation.envelopeNumber < 1 then
                newMouseOverHeight = newMouseOverTrackHeight

                correctScrollMouseOffsetPixels = mainViewOrigMouseLocation.trackRatio * newMouseOverHeight

            -- The mouse is over an envelope.
            else
                local newMouseOverFullLaneHeight = initallyVisibleTracks[mainViewOrigMouseLocation.trackNumber].currentLaneHeight
                newMouseOverHeight = newMouseOverFullLaneHeight - newMouseOverTrackHeight

                correctScrollMouseOffsetPixels = mainViewOrigMouseLocation.fullEnvelopeLaneRatio * newMouseOverHeight + newMouseOverTrackHeight
            end
        end

        -- Add on the 5 extra pixels after the master track if it is visible.
        if masterIsVisibleInTCP() then
            correctScrollPosition = correctScrollPosition + 5
        end

        correctScrollPosition = correctScrollPosition + correctScrollMouseOffsetPixels - mainViewOrigMouseClientLocation.y

        local _, scrollPos, scrollPageSize, scrollMin, scrollMax, scrollTrackPos = reaper.JS_Window_GetScrollInfo(arrangeWindow, "VERT")

        if correctScrollPosition + scrollPageSize > scrollMax and scrollMax > windowHeight then
            setUIRefresh(true)
            createPaddingTrack()
        end

        setMainViewVerticalScroll(correctScrollPosition)
    end
end

function setMainViewVerticalZoom(zoom)
    setUIRefresh(false)

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

    if usePreciseMainViewHorizontalPositionTracking then
        correctMainViewHorizontalScroll()
    end
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
        adjustMainViewHorizontalZoom(xAdjust * arrangeXZoomFactor)

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
        setMainViewVerticalZoom(2.0 ^ (yAccumAdjust * arrangeYZoomFactor))
    end

    -- =======================================================

    previousXAccumAdjust = xAccumAdjust
    previousYAccumAdjust = yAccumAdjust

    reaper.JS_Mouse_SetPosition(initialMousePos.x, initialMousePos.y)

    reaper.defer(update)
end

function atExit()
    -- Clean up the padding track.
    if trackIsValid(paddingTrack) then
        reaper.DeleteTrack(paddingTrack)
    end

    -- Release any intercepts.
    reaper.JS_WindowMessage_ReleaseAll()

    -- Stop intercepting keyboard input.
    reaper.JS_VKeys_Intercept(-1, -1)
end

init()