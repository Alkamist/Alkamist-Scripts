local reaper = reaper
local gfx = gfx
local gfxUpdate = gfx.update
local gfxInit = gfx.init

local GUI = {
    mouseCap = 0,
    mouseX = 0,
    mouseY = 0,
    mouseWheel = 0,
    mouseHWheel = 0,
    keyboardChar = nil,
    windowTitle = "",
    windowX = 0,
    windowY = 0,
    windowWidth = 0,
    windowHeight = 0,
    windowDock = 0,
    leftMouseButtonIsPressed = false,
    middleMouseButtonIsPressed = false,
    rightMouseButtonIsPressed = false,
    shiftKeyIsPressed = false,
    controlKeyIsPressed = false,
    windowsKeyIsPressed = false,
    altKeyState = false
}

function GUI.setBackgroundColor(r, g, b)
    gfx.clear = r * 255 + g * 255 * 256 + b * 255 * 65536
end
function GUI.initialize(title, width, height, dock, x, y)
    local title = title or GUI.windowTitle or ""
    local x = x or GUI.windowX or 0
    local y = y or GUI.windowY or 0
    local width = width or GUI.windowWidth  or 0
    local height = height or GUI.windowHeight or 0
    local dock = dock or GUI.windowDock or 0

    GUI.windowTitle = title
    GUI.windowX = x
    GUI.windowY = y
    GUI.windowWidth = width
    GUI.windowHeight = height
    GUI.windowDock = dock

    gfxInit(title, width, height, dock, x, y)
end
function GUI.update() end
function GUI.run()
    local timer = reaper.time_precise()

    local mouseCap = gfx.mouse_cap
    GUI.mouseCap = mouseCap
    GUI.mouseX = gfx.mouse_x
    GUI.mouseY = gfx.mouse_y
    GUI.mouseWheel = gfx.mouse_wheel / 120
    gfx.mouse_wheel = 0
    GUI.mouseHWheel = gfx.mouse_hwheel / 120
    gfx.mouse_hwheel = 0

    local char = gfx.getchar()
    GUI.keyboardChar = char

    GUI.windowWidth = gfx.w
    GUI.windowHeight = gfx.h

    GUI.leftMouseButtonIsPressed = mouseCap & 1 == 1
    GUI.middleMouseButtonIsPressed = mouseCap & 64 == 64
    GUI.rightMouseButtonIsPressed = mouseCap & 2 == 2
    GUI.shiftKeyIsPressed = mouseCap & 8 == 8
    GUI.controlKeyIsPressed = mouseCap & 4 == 4
    GUI.windowsKeyIsPressed = mouseCap & 32 == 32
    GUI.altKeyIsPressed = mouseCap & 16 == 16

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