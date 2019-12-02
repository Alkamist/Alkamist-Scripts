local reaper = reaper
local gfx = gfx
local gfxUpdate = gfx.update
local gfxInit = gfx.init

local mouseCap = 0
local mouseX = 0
local mouseY = 0
local mouseWheel = 0
local mouseHWheel = 0
local keyboardChar = nil
local windowTitle = ""
local windowX = 0
local windowY = 0
local windowWidth = 0
local windowHeight = 0
local windowDock = 0
local leftMouseButtonState = false
local middleMouseButtonState = false
local rightMouseButtonState = false
local shiftKeyState = false
local controlKeyState = false
local windowsKeyState = false
local altKeyState = false

local GUI = {
    getMouseCap = function() return mouseCap end,
    getMouseX = function() return mouseX end,
    getMouseY = function() return mouseY end,
    getMouseWheel = function() return mouseWheel end,
    getMouseHWheel = function() return mouseHWheel end,
    getKeyboardChar = function() return keyboardChar end,
    getWindowTitle = function() return windowTitle end,
    getWindowX = function() return windowX end,
    getWindowY = function() return windowY end,
    getWindowWidth = function() return windowWidth end,
    getWindowHeight = function() return windowHeight end,
    getWindowDock = function() return windowDock end,
    leftMouseButtonIsPressed = function() return leftMouseButtonState end,
    middleMouseButtonIsPressed = function() return middleMouseButtonState end,
    rightMouseButtonIsPressed = function() return rightMouseButtonState end,
    shiftKeyIsPressed = function() return shiftKeyState end,
    controKeyIsPressed = function() return controlKeyState end,
    windowsKeyIsPressed = function() return windowsKeyState end,
    altKeyIsPressed = function() return altKeyState end
}

function GUI.setBackgroundColor(r, g, b)
    gfx.clear = r * 255 + g * 255 * 256 + b * 255 * 65536
end
function GUI.initialize(title, width, height, dock, x, y)
    local title = title or windowTitle or ""
    local x = x or windowX or 0
    local y = y or windowY or 0
    local width = width or windowWidth  or 0
    local height = height or windowHeight or 0
    local dock = dock or windowDock or 0

    windowTitle = title
    windowX = x
    windowY = y
    windowWidth = width
    windowHeight = height
    windowDock = dock

    gfxInit(title, width, height, dock, x, y)
end
function GUI.update() end
function GUI.run()
    local timer = reaper.time_precise()

    mouseCap = gfx.mouse_cap
    mouseX = gfx.mouse_x
    mouseY = gfx.mouse_y
    mouseCap = mouseCap
    mouseWheel = gfx.mouse_wheel / 120
    gfx.mouse_wheel = 0
    mouseHWheel = gfx.mouse_hwheel / 120
    gfx.mouse_hwheel = 0

    local char = gfx.getchar()
    keyboardChar = char

    windowWidth = gfx.w
    windowHeight = gfx.h

    leftMouseButtonState = mouseCap & 1 == 1
    middleMouseButtonState = mouseCap & 64 == 64
    rightMouseButtonState = mouseCap & 2 == 2
    shiftKeyState = mouseCap & 8 == 8
    controlKeyState = mouseCap & 4 == 4
    windowsKeyState = mouseCap & 32 == 32
    altKeyState = mouseCap & 16 == 16

    -- Pass through the space bar.
    if char == 32 then reaper.Main_OnCommandEx(40044, 0, 0) end

    GUI.update()

    -- Keep the window open unless escape or the close button are pushed.
    if char ~= 27 and char ~= -1 then reaper.defer(GUI.run) end
    gfxUpdate()

    gfx.x = 1
    gfx.y = 1
    gfx.set(0.7, 0.7, 0.7, 1, 0)
    local fps = 1 / (reaper.time_precise() - timer)
    gfx.drawnumber(fps, 1)
end

return GUI