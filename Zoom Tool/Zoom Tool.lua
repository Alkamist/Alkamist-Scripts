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

    reaper.defer(update)
end

local previousYAdjustment = 0
local yZoomTick = 0.5
local yAdjustment = 0
function update()
    if scriptShouldStop() then return 0 end
    --reaper.PreventUIRefresh(1)

    currentMousePos.x, currentMousePos.y = reaper.GetMousePosition()

    local xAdjustment = (currentMousePos.x - initialMousePos.x) * mouseSensitivity
    local yRelativeAdjustment = (currentMousePos.y - initialMousePos.y) * mouseSensitivity
    yAdjustment = yAdjustment + yRelativeAdjustment
    --local yAdjustment = (currentMousePos.y - initialMousePos.y) * mouseSensitivity

    previousMousePos.x = currentMousePos.x
    previousMousePos.y = currentMousePos.y

    -- Horizontal zoom is easy.
    reaper.adjustZoom(xAdjustment, 0, true, -1)

    local tickLowValue = yZoomTick * math.floor(yAdjustment / yZoomTick)
    local tickHighValue = yZoomTick * math.ceil(yAdjustment / yZoomTick)

    if previousYAdjustment < tickLowValue then
        reaperCMD(40111) -- zoom in vertical
    elseif previousYAdjustment > tickHighValue then
        reaperCMD(40112) -- zoom out vertical
    end

    previousYAdjustment = yAdjustment

    reaper.JS_Mouse_SetPosition(initialMousePos.x, initialMousePos.y)

    --reaper.PreventUIRefresh(-1)

    reaper.defer(update)
end

init()