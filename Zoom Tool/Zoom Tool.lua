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

function atExit()
    -- Release any intercepts.
    reaper.JS_WindowMessage_ReleaseAll()

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

    -- Load REAPER's native "zoom" cursor
    reaper.JS_Mouse_SetCursor(reaper.JS_Mouse_LoadCursor(1009))

    -- Prevent REAPER from changing cursor back, by intercepting "SETCURSOR" messages
    reaper.JS_WindowMessage_Intercept(focusedWindow, "WM_SETCURSOR", false)

    -- Intercept keyboard input.
    reaper.JS_VKeys_Intercept(-1, 1)

    mouseState = reaper.JS_Mouse_GetState(0xFF)
    startTime = reaper.time_precise()
    keyState = reaper.JS_VKeys_GetState(-2):sub(VKLow, VKHi)

    thisCycleTime = reaper.time_precise()

    initialMousePos.x, initialMousePos.y = reaper.GetMousePosition()

    reaper.defer(update)
end

local previousYAdjustment = 0
local yZoomTick = 0.3
local yAdjustment = 0
function update()
    if scriptShouldStop() then return 0 end
    --reaper.PreventUIRefresh(1)

    currentMousePos.x, currentMousePos.y = reaper.GetMousePosition()

    local xAdjustment = (currentMousePos.x - initialMousePos.x) * mouseSensitivity
    local yRelativeAdjustment = (currentMousePos.y - initialMousePos.y) * mouseSensitivity
    yAdjustment = yAdjustment + yRelativeAdjustment

    -- Handle horizontal zoom.
    reaper.adjustZoom(xAdjustment, 0, true, -1)

    -- Handle vertical zoom.
    local tickLowValue = yZoomTick * math.floor(yAdjustment / yZoomTick)
    local tickHighValue = yZoomTick * math.ceil(yAdjustment / yZoomTick)

    if previousYAdjustment < tickLowValue then
        local overflow = math.ceil((tickLowValue - previousYAdjustment) / yZoomTick)
        for i = 1, overflow do
            reaperCMD(40111) -- zoom in vertical
            reaper.JS_Mouse_SetPosition(initialMousePos.x, initialMousePos.y)
        end

    elseif previousYAdjustment > tickHighValue then
        local overflow = math.ceil((previousYAdjustment - tickHighValue) / yZoomTick)
        for i = 1, overflow do
            reaperCMD(40112) -- zoom out vertical
            reaper.JS_Mouse_SetPosition(initialMousePos.x, initialMousePos.y)
        end
    end

    previousYAdjustment = yAdjustment

    reaper.JS_Mouse_SetPosition(initialMousePos.x, initialMousePos.y)

    --reaper.PreventUIRefresh(-1)

    reaper.defer(update)
end

init()