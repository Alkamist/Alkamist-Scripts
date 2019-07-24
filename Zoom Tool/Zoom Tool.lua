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
local previousMousePos = {}
local currentMousePos = {}
local initalTrackHeights = {}

local focusedWindow =  reaper.JS_Window_GetFocus()
local yAdjustment = 0

local originallyVisibleTracks = {}



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

function trackIsValid(track)
    local trackExists = reaper.ValidatePtr(track, "MediaTrack*")
    return track ~= nil and trackExists
end

function getTCPTracksOnScreen()
    local tracksOnScreen = {}

    local trackPixelStart = 0
    local _, scrollPos, scrollPageSize, scrollMin, scrollMax, scrollTrackPos = reaper.JS_Window_GetScrollInfo(focusedWindow, "VERT")

    local trackIndex = 1
    for i = 1, reaper.CountTracks(0) do
        local currentTrack = reaper.GetTrack(0, i - 1)
        trackPixelEnd = trackPixelStart + reaper.GetMediaTrackInfo_Value(currentTrack, "I_WNDH")

        local screenStart = scrollPos
        local screenEnd = scrollPos + scrollPageSize

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

function moveVerticalScroll(value)
    local _, scrollPos, scrollPageSize, scrollMin, scrollMax, scrollTrackPos = reaper.JS_Window_GetScrollInfo(focusedWindow, "VERT")
    reaper.JS_Window_SetScrollPos(focusedWindow, "VERT", math.max(math.floor(scrollPos + value), 0))
end

local tracksOnScreen = getTCPTracksOnScreen()
local tempHiddenTracks = {}
local hideScrollCorrection = 0
local paddingTracksBeforeHide = 50
function hideOffScreenTracks()
    if trackIsValid(tracksOnScreen[1]) and trackIsValid(tracksOnScreen[#tracksOnScreen]) then
        local firstOnScreenTrack = tracksOnScreen[1]
        local firstOnScreenTrackNumber = reaper.GetMediaTrackInfo_Value(firstOnScreenTrack, "IP_TRACKNUMBER")
        local lastOnScreenTrack = tracksOnScreen[#tracksOnScreen]
        local lastOnScreenTrackNumber = reaper.GetMediaTrackInfo_Value(lastOnScreenTrack, "IP_TRACKNUMBER")

        local hiddenTrackIndex = 1
        for i = 1, #originallyVisibleTracks do
            if trackIsValid(originallyVisibleTracks[i]) then
                local currentTrack = originallyVisibleTracks[i]
                local currentTrackNumber = reaper.GetMediaTrackInfo_Value(currentTrack, "IP_TRACKNUMBER")

                if currentTrackNumber < firstOnScreenTrackNumber - paddingTracksBeforeHide - 1 then
                    hideScrollCorrection = hideScrollCorrection + reaper.GetMediaTrackInfo_Value(currentTrack, "I_WNDH")
                end

                if currentTrackNumber < firstOnScreenTrackNumber - paddingTracksBeforeHide - 1 or currentTrackNumber > lastOnScreenTrackNumber + paddingTracksBeforeHide then
                    reaper.SetMediaTrackInfo_Value(currentTrack, "B_SHOWINTCP", 0);
                    reaper.SetMediaTrackInfo_Value(currentTrack, "B_SHOWINMIXER", 0);
                    tempHiddenTracks[hiddenTrackIndex] = currentTrack
                    hiddenTrackIndex = hiddenTrackIndex + 1
                end
            end
        end

        moveVerticalScroll(-hideScrollCorrection)
    end
end

function showTempHiddenTracks()
    for i = 1, #tempHiddenTracks do
        if trackIsValid(tempHiddenTracks[i]) then
            reaper.SetMediaTrackInfo_Value(tempHiddenTracks[i], "B_SHOWINTCP", 1);
            reaper.SetMediaTrackInfo_Value(tempHiddenTracks[i], "B_SHOWINMIXER", 1);
        end
    end

    moveVerticalScroll(hideScrollCorrection)
end

function zoomAllTracksToAdjustment()
    --reaper.PreventUIRefresh(1)

    local _, previousScrollPos, previousScrollPageSize, previousScrollMin, previousScrollMax, previousScrollTrackPos = reaper.JS_Window_GetScrollInfo(focusedWindow, "VERT")
    local scrollRatio = previousScrollPos / previousScrollMax

    for i = 1, reaper.CountTracks(0) do
        local currentTrack = reaper.GetTrack(0, i - 1)
        local trackHeight = initalTrackHeights[i] + yAdjustment
        local trackHeight = math.max(trackHeight, 0)

        reaper.SetMediaTrackInfo_Value(currentTrack, "I_HEIGHTOVERRIDE", trackHeight);
    end
    reaper.TrackList_AdjustWindows(false)

    local tracksOnScreen = getTCPTracksOnScreen()
    local firstTrackOnScreenNumber = reaper.GetMediaTrackInfo_Value(tracksOnScreen[1], "IP_TRACKNUMBER")

    local scrollAccumulation = 0
    for i = 1, firstTrackOnScreenNumber - 1 do
        local currentTrack = reaper.GetTrack(0, i - 1)

        local shiftValue = reaper.GetMediaTrackInfo_Value(currentTrack, "I_WNDH") - initalTrackHeights[i]
        scrollAccumulation = scrollAccumulation + shiftValue
    end

    local _, scrollPos, scrollPageSize, scrollMin, scrollMax, scrollTrackPos = reaper.JS_Window_GetScrollInfo(focusedWindow, "VERT")
    local unwantedScrollMovement = scrollPos - previousScrollPos
    --msg(unwantedScrollMovement)

    local scrollShift = scrollAccumulation-- - unwantedScrollMovement
    reaper.JS_Window_SetScrollPos(focusedWindow, "VERT", math.max(math.floor(previousScrollPos + scrollShift), 0))

    --reaper.PreventUIRefresh(-1)
end

function atExit()
    --zoomAllTracksToAdjustment()
    --showTempHiddenTracks()
    --reaper.TrackList_AdjustWindows(false)

    -- Stop intercepting keyboard input.
    reaper.JS_VKeys_Intercept(-1, -1)
end

function scriptShouldStop()
    local prevCycleTime = thisCycleTime or startTime
    thisCycleTime = reaper.time_precise()
    dragTimeStarted = dragTimeStarted or (thisCycleTime > startTime + dragTime)

    local prevKeyState = keyState
    keyState = reaper.JS_VKeys_GetState(startTime - 0.5):sub(VKLow, VKHi)
    if dragTimeStarted and keyState ~= prevKeyState and keyState == VKState0 then
        return true
    end

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

    local previousMouseState = mouseState or 0xFF
    mouseState = reaper.JS_Mouse_GetState(0xFF)
    if (mouseState & 61) > (previousMouseState & 61) -- 61 = 0b00111101 = Ctrl | Shift | Alt | Win | Left button
    or (dragTimeStarted and (mouseState & 1) < (previousMouseState & 1)) then
        return true
    end

    return false
end

function init()
    reaper.atexit(atExit)

    -- Intercept keyboard input.
    reaper.JS_VKeys_Intercept(-1, 1)

    mouseState = reaper.JS_Mouse_GetState(0xFF)
    startTime = reaper.time_precise()
    keyState = reaper.JS_VKeys_GetState(-2):sub(VKLow, VKHi)

    thisCycleTime = reaper.time_precise()

    initialMousePos.x, initialMousePos.y = reaper.GetMousePosition()
    previousMousePos.x, previousMousePos.y = reaper.GetMousePosition()

    local trackIndex = 1
    for i = 1, reaper.CountTracks(0) do
        local currentTrack = reaper.GetTrack(0, i - 1)

        if reaper.IsTrackVisible(currentTrack, false) then
            if trackIsValid(currentTrack) then
                originallyVisibleTracks[trackIndex] = currentTrack

                initalTrackHeights[trackIndex] = reaper.GetMediaTrackInfo_Value(currentTrack, "I_WNDH")
                trackIndex = trackIndex + 1
            end
        end
    end

    --hideOffScreenTracks()

    reaper.defer(update)
end

function update()
    if scriptShouldStop() then return 0 end
    reaper.PreventUIRefresh(1)

    currentMousePos.x, currentMousePos.y = reaper.GetMousePosition()

    local xAdjustment = (currentMousePos.x - previousMousePos.x) * mouseSensitivity
    yAdjustment = (currentMousePos.y - initialMousePos.y) * mouseSensitivity * 3.0
    local yRelativeAdjustment = (currentMousePos.y - previousMousePos.y) * mouseSensitivity * 3.0

    previousMousePos.x = currentMousePos.x
    previousMousePos.y = currentMousePos.y

    -- Horizontal zoom is easy.
    reaper.adjustZoom(xAdjustment, 0, true, -1)

    -- Vertical zoom is a bit more complicated.
    for i = 1, #tracksOnScreen do
        local currentTrack = tracksOnScreen[i]
        local currentTrackNumber = reaper.GetMediaTrackInfo_Value(currentTrack, "IP_TRACKNUMBER")

        --local trackHeight = initalTrackHeights[currentTrackNumber] + yAdjustment
        --local trackHeight = math.max(trackHeight, 0)

        --reaper.SetMediaTrackInfo_Value(currentTrack, "I_HEIGHTOVERRIDE", trackHeight);
    end
    reaper.TrackList_AdjustWindows(false)

    --local _, scrollPos, scrollPageSize, scrollMin, scrollMax, scrollTrackPos = reaper.JS_Window_GetScrollInfo(focusedWindow, "VERT")
    --local scrollScaleFactor = 7.0
    --local newScrollPos = scrollPos + yRelativeAdjustment * scrollScaleFactor
    --reaper.JS_Window_SetScrollPos(focusedWindow, "VERT", math.max(math.floor(testScroll), 0))

    -- We need to scroll as we zoom to keep the track under the cursor in view.
    --_, scrollPos, scrollPageSize, scrollMin, scrollMax, scrollTrackPos = reaper.JS_Window_GetScrollInfo(focusedWindow, "VERT")

    --local scrollScaleFactor = 7.0
    --local newScrollPos = math.max(scrollPos + yRelativeAdjustment * scrollScaleFactor, 0)

    --reaper.JS_Window_SetScrollPos(focusedWindow, "VERT", math.floor(newScrollPos))

    reaper.PreventUIRefresh(-1)

    reaper.defer(update)
end

init()