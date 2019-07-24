-- @description Zoom Tool
-- @version 1.0
-- @author Alkamist
-- @donate https://paypal.me/CoreyLehmanMusic
-- @about
--   This script will activate a zoom tool similar to what is used in Melodyne.

local mouseSensitivity = 0.1

local VKLow, VKHi = 8, 0xFE -- Range of virtual key codes to check for key presses.
local VKState0 = string.rep("\0", VKHi - VKLow + 1)

local dragTime = 0.5 -- How long must the shortcut key be held down before left-drag is activated?
local dragTimeStarted = false
local startTime = 0
local thisCycleTime = 0

local mouseState = nil
local keyState = nil

local initialMousePos = {}
local currentMousePos = {}

local focusedWindow = reaper.JS_Window_GetFocus()



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

function reaperMIDICMD(id)
    if type(id) == "string" then
        reaper.MIDIEditor_LastFocused_OnCommand(reaper.NamedCommandLookup(id), 0)
    else
        reaper.MIDIEditor_LastFocused_OnCommand(id, 0)
    end
end

function atExit()
    -- Release any intercepts.
    reaper.JS_WindowMessage_ReleaseAll()

    -- Stop intercepting keyboard input.
    reaper.JS_VKeys_Intercept(-1, -1)
end

function scriptShouldStop()
    local prevCycleTime = thisCycleTime or startTime
    thisCycleTime = reaper.time_precise()

    local prevKeyState = keyState
    keyState = reaper.JS_VKeys_GetState(startTime - 0.5):sub(VKLow, VKHi)

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

    -- Prevent REAPER from changing cursor back, by intercepting "SETCURSOR" messages
    reaper.JS_WindowMessage_Intercept(focusedWindow, "WM_SETCURSOR", false)

    -- Intercept keyboard input.
    reaper.JS_VKeys_Intercept(-1, 1)

    -- Initialize mouse and keyboard states.
    mouseState = reaper.JS_Mouse_GetState(0xFF)
    keyState = reaper.JS_VKeys_GetState(-2):sub(VKLow, VKHi)

    initialMousePos.x, initialMousePos.y = reaper.GetMousePosition()

    -- Find out what kind of window is under the mouse and focus it.
    windowUnderMouse = reaper.JS_Window_FromPoint(initialMousePos.x, initialMousePos.y)
    if windowUnderMouse then
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

            -- Window under mouse is the main editor.
            elseif parentWindow == reaper.GetMainHwnd() then
                reaper.JS_Window_SetFocus(windowUnderMouse)
                windowType = "main"
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

local previousXAccumAdjust = 0
local previousYAccumAdjust = 0
local xZoomTick = 1
local yZoomTick = 0.3
local xAccumAdjust = 0
local yAccumAdjust = 0
function update()
    if scriptShouldStop() then return 0 end

    if not midiSelectionRestored then
        restoreMIDISelection()
    end

    currentMousePos.x, currentMousePos.y = reaper.GetMousePosition()

    -- ==================== HORIZONTAL ZOOM ====================

    local xAdjust = (currentMousePos.x - initialMousePos.x) * mouseSensitivity
    xAccumAdjust = xAccumAdjust + xAdjust

    -- Handle horizontal zoom in main view.
    if windowType == "main" then
        reaper.adjustZoom(xAdjust, 0, true, -1)

    -- I can't find a way to adjust the MIDI editor's zoom via the API,
    -- so I have to do it with Reaper actions.
    elseif windowType == "midi" then
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

    local yAdjust = (currentMousePos.y - initialMousePos.y) * mouseSensitivity
    yAccumAdjust = yAccumAdjust + yAdjust

    local tickLowValue = yZoomTick * math.floor(yAccumAdjust / yZoomTick)
    local tickHighValue = yZoomTick * math.ceil(yAccumAdjust / yZoomTick)

    if previousYAccumAdjust < tickLowValue then
        local overflow = math.ceil((tickLowValue - previousYAccumAdjust) / yZoomTick)
        for i = 1, overflow do
            if windowType == "main" then
                reaperCMD(40111) -- zoom in vertical
            elseif windowType == "midi" then
                reaperMIDICMD(40111) -- zoom in vertical
            end
            reaper.JS_Mouse_SetPosition(initialMousePos.x, initialMousePos.y)
        end

    elseif previousYAccumAdjust > tickHighValue then
        local overflow = math.ceil((previousYAccumAdjust - tickHighValue) / yZoomTick)
        for i = 1, overflow do
            if windowType == "main" then
                reaperCMD(40112) -- zoom out vertical
            elseif windowType == "midi" then
                reaperMIDICMD(40112) -- zoom out vertical
            end
            reaper.JS_Mouse_SetPosition(initialMousePos.x, initialMousePos.y)
        end
    end

    -- =======================================================

    previousXAccumAdjust = xAccumAdjust
    previousYAccumAdjust = yAccumAdjust

    reaper.JS_Mouse_SetPosition(initialMousePos.x, initialMousePos.y)

    reaper.defer(update)
end

init()