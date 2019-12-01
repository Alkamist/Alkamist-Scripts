local reaper = reaper
local gfx = gfx
local gfxUpdate = gfx.update
local gfxInit = gfx.init

local mouseCap = { 0, 0 }
local mouseX = { 0, 0 }
local mouseY = { 0, 0 }
local mouseWheel = { 0, 0 }
local mouseHWheel = { 0, 0 }
local keyboardChar = { nil, nil }
local windowTitle = { "", "" }
local windowX = { 0, 0 }
local windowY = { 0, 0 }
local windowWidth = { 0, 0 }
local windowHeight = { 0, 0 }
local windowDock = { 0, 0 }
local leftMouseButtonState = { false, false }
local middleMouseButtonState = { false, false }
local rightMouseButtonState = { false, false }
local shiftKeyState = { false, false }
local controlKeyState = { false, false }
local windowsKeyState = { false, false }
local altKeyState = { false, false }

--local leftBitValue = 1
--local middleBitValue = 64
--local rightBitValue = 2
--local shiftBitValue = 8
--local controlBitValue = 4
--local windowsBitValue = 32
--local altBitValue = 16
--
--local function getMouseButtonState(mouseCap, bitValue) return mouseCap & bitValue == bitValue end
--local gfxGetChar = gfx.getchar
--local function getKeyState(character)
--    return gfxGetChar(characterTable[character]) > 0
--end

local GUI = {
    mouseCap = mouseCap,
    mouseX = mouseX,
    mouseY = mouseY,
    mouseWheel = mouseWheel,
    mouseHWheel = mouseHWheel,
    keyboardChar = keyboardChar,
    windowTitle = windowTitle,
    windowX = windowX,
    windowY = windowY,
    windowWidth = windowWidth,
    windowHeight = windowHeight,
    windowDock = windowDock,
    leftMouseButtonState = leftMouseButtonState,
    middleMouseButtonState = middleMouseButtonState,
    rightMouseButtonState = rightMouseButtonState,
    shiftKeyState = shiftKeyState,
    controlKeyState = controlKeyState,
    windowsKeyState = windowsKeyState,
    altKeyState = altKeyState
}

function GUI.setBackgroundColor(r, g, b)
    gfx.clear = r * 255 + g * 255 * 256 + b * 255 * 65536
end
function GUI.initialize(title, width, height, dock, x, y)
    local title = title or windowTitle[1] or ""
    local x = x or windowX[1] or 0
    local y = y or windowY[1] or 0
    local width = width or windowWidth[1]  or 0
    local height = height or windowHeight[1] or 0
    local dock = dock or windowDock[1] or 0

    windowTitle[1], windowTitle[2] = title
    windowX[1], windowX[2] = x
    windowY[1], windowY[2] = y
    windowWidth[1], windowWidth[2] = width
    windowHeight[1], windowHeight[2] = height
    windowDock[1], windowDock[2] = dock

    gfxInit(title, width, height, dock, x, y)
end
function GUI.update() end
function GUI.run()
    local timer = reaper.time_precise()

    mouseX[1] = gfx.mouse_x
    mouseY[1] = gfx.mouse_y
    mouseCap[1] = gfx.mouse_cap
    mouseWheel[1] = gfx.mouse_wheel / 120
    gfx.mouse_wheel = 0
    mouseHWheel[1] = gfx.mouse_hwheel / 120
    gfx.mouse_hwheel = 0

    local char = gfx.getchar()
    keyboardChar[1] = char

    windowWidth[1] = gfx.w
    windowHeight[1] = gfx.h

    leftMouseButtonState[1] = mouseCap & 1 == 1
    middleMouseButtonState[1] = mouseCap & 64 == 64
    rightMouseButtonState[1] = mouseCap & 2 == 2
    shiftKeyState[1] = mouseCap & 8 == 8
    controlKeyState[1] = mouseCap & 4 == 4
    windowsKeyState[1] = mouseCap & 32 == 32
    altKeyState[1] = mouseCap & 16 == 16

    -- Pass through space.
    if char == 32 then reaper.Main_OnCommandEx(40044, 0, 0) end

    GUI.update()

    -- Keep the window open unless escape or the close button are pushed.
    if char ~= 27 and char ~= -1 then reaper.defer(GUI.run) end
    gfxUpdate()

    mouseCap[2] = mouseCap[1]
    mouseX[2] = mouseX[1]
    mouseY[2] = mouseY[1]
    mouseWheel[2] = mouseWheel[1]
    mouseHWheel[2] = mouseHWheel[1]
    keyboardChar[2] = keyboardChar[1]
    windowTitle[2] = windowTitle[1]
    windowX[2] = windowX[1]
    windowY[2] = windowY[1]
    windowWidth[2] = windowWidth[1]
    windowHeight[2] = windowHeight[1]
    windowDock[2] = windowDock[1]
    leftMouseButtonState[2] = leftMouseButtonState[1]
    middleMouseButtonState[2] = middleMouseButtonState[1]
    rightMouseButtonState[2] = rightMouseButtonState[1]
    shiftKeyState[2] = shiftKeyState[1]
    controlKeyState[2] = controlKeyState[1]
    windowsKeyState[2] = windowsKeyState[1]
    altKeyState[2] = altKeyState[1]

    gfx.x = 1
    gfx.y = 1
    gfx.set(0.7, 0.7, 0.7, 1, 0)
    local fps = 1 / (reaper.time_precise() - timer)
    gfx.drawnumber(fps, 1)
end

return GUI