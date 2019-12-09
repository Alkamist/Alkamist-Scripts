local reaper = reaper
local reaperTimePrecise = reaper.time_precise
local reaperMainOnCommandEx = reaper.Main_OnCommandEx
local reaperDefer = reaper.defer

local gfx = gfx
local gfxUpdate = gfx.update
local gfxInit = gfx.init
local gfxGetChar = gfx.getchar
local gfxSet = gfx.set
local gfxRect = gfx.rect
local gfxLine = gfx.line
local gfxCircle = gfx.circle
local gfxTriangle = gfx.triangle
local gfxRoundRect = gfx.roundrect
local gfxSetFont = gfx.setfont
local gfxMeasureStr = gfx.measurestr
local gfxDrawStr = gfx.drawstr

local type = type

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

--local function updateMouseButton(self, bitValue)
--    self.wasPreviouslyPressed = self.isPressed
--    self.previousX = self.x
--    self.previousY = self.y
--
--    self.x = GUI.mouseX
--    self.y = GUI.mouseY
--    self.justMoved = self.x
--    self.isPressed = GUI.mouseCap & bitValue == bitValue
--    self.justPressed = self.isPressed and not self.wasPreviouslyPressed
--    self.justReleased = not self.isPressed and self.wasPreviouslyPressed
--    self.justDragged = self.isPressed and
--end

function GUI.setColor(rOrColor, g, b)
    if type(rOrColor) == "number" then
        gfxSet(rOrColor, g, b, gfx.a or 1, gfx.mode or 0)
    else
        local alpha = rOrColor[4] or gfx.a or 1
        local blendMode = rOrColor[5] or gfx.mode or 0
        gfxSet(rOrColor[1], rOrColor[2], rOrColor[3], alpha, blendMode)
    end
end
function GUI.drawRectangle(x, y, w, h, filled)
    gfxRect(x, y, w, h, filled)
end
function GUI.drawLine(x, y, x2, y2, antiAliased)
    gfxLine(x, y, x2, y2, antiAliased)
end
function GUI.drawCircle(x, y, r, filled, antiAliased)
    gfxCircle(x, y, r, filled, antiAliased)
end
function GUI.drawString(str, x, y, x2, y2, flags)
    gfx.x = x
    gfx.y = y
    if flags then
        gfxDrawStr(str, flags, x2, y2)
    else
        gfxDrawStr(str)
    end
end
function GUI.setFont(fontName, fontSize)
    gfxSetFont(1, fontName, fontSize)
end
function GUI.measureString(str)
    return gfxMeasureStr(str)
end

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
function GUI.update(dt) end

local currentTime = reaperTimePrecise()
local previousTime = currentTime
function GUI.run()
    local timer = reaperTimePrecise()

    local mouseCap = gfx.mouse_cap
    GUI.mouseCap = mouseCap
    GUI.mouseX = gfx.mouse_x
    GUI.mouseY = gfx.mouse_y
    GUI.mouseWheel = gfx.mouse_wheel / 120
    gfx.mouse_wheel = 0
    GUI.mouseHWheel = gfx.mouse_hwheel / 120
    gfx.mouse_hwheel = 0

    local char = gfxGetChar()
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
    if char == 32 then reaperMainOnCommandEx(40044, 0, 0) end

    currentTime = reaperTimePrecise()
    GUI.update(currentTime - previousTime)
    previousTime = currentTime

    -- Keep the window open unless escape or the close button are pushed.
    if char ~= 27 and char ~= -1 then reaperDefer(GUI.run) end
    gfxUpdate()

    gfx.x = 1
    gfx.y = 1
    gfx.set(0.7, 0.7, 0.7, 1, 0)
    gfx.drawnumber(1 / (reaperTimePrecise() - timer), 1)
end

return GUI