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
    previousMouseCap = 0,
    mouseX = 0,
    previousMouseX = 0,
    mouseY = 0,
    previousMouseY = 0,
    mouseWheel = 0,
    mouseWheelJustMoved = false,
    mouseHWheel = 0,
    mouseHWheelJustMoved = false,
    keyboardChar = nil,
    windowTitle = "",
    windowX = 0,
    windowY = 0,
    windowWidth = 0,
    previousWindowWidth = 0,
    windowWidthChange = 0,
    windowWidthJustChanged = false,
    windowHeight = 0,
    previousWindowHeight = 0,
    windowHeightChange = 0,
    windowHeightJustChanged = false,
    windowWasJustResized = false,
    windowDock = 0,
    systems = {}
}

local function initializeMouseButton(bitValue)
    local self = {}
    self.bitValue = bitValue
    self.trackedObjects = {}
    self.wasPressedInsideObject = {}
    self.justPressedObject = {}
    self.justReleasedObject = {}
    self.justDraggedObject = {}
    return self
end
local function updateMouseButtonState(self)
    self.isPressed = GUI.mouseCap & self.bitValue == self.bitValue
    self.justPressed = self.isPressed and not self.wasPreviouslyPressed
    self.justReleased = not self.isPressed and self.wasPreviouslyPressed
    self.justDragged = self.isPressed and GUI.mouseJustMoved

    local trackedObjects = self.trackedObjects
    for i = 1, #trackedObjects do
        local object = trackedObjects[i]

        if object:pointIsInside(GUI.mouseX, GUI.mouseY) and self.justPressed then
            self.wasPressedInsideObject[object] = true
        end

        self.justPressedObject[object] = self.justPressed and self.wasPressedInsideObject[object]
        self.justReleasedObject[object] = self.justReleased and self.wasPressedInsideObject[object]
        self.justDraggedObject[object] = self.justDragged and self.wasPressedInsideObject[object]

        if self.justReleased then self.wasPressedInsideObject[object] = false end
    end
end
local function updateMouseButtonPreviousState(self)
    self.wasPreviouslyPressed = self.isPressed
end

GUI.leftMouseButton = initializeMouseButton(1)
GUI.middleMouseButton = initializeMouseButton(64)
GUI.rightMouseButton = initializeMouseButton(2)
GUI.shiftKey = initializeMouseButton(8)
GUI.controlKey = initializeMouseButton(4)
GUI.windowsKey = initializeMouseButton(32)
GUI.altKey = initializeMouseButton(16)

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
    GUI.previousWindowWidth = width
    GUI.windowHeight = height
    GUI.previousWindowHeight = height
    GUI.windowDock = dock

    gfxInit(title, width, height, dock, x, y)
end

function GUI.update(dt) end

local function updateGUIStates()
    GUI.mouseCap = gfx.mouse_cap
    GUI.mouseX = gfx.mouse_x
    GUI.mouseY = gfx.mouse_y
    GUI.mouseWheel = gfx.mouse_wheel / 120
    gfx.mouse_wheel = 0
    GUI.mouseHWheel = gfx.mouse_hwheel / 120
    gfx.mouse_hwheel = 0

    GUI.mouseWheelJustMoved = GUI.mouseWheel ~= 0
    GUI.mouseHWheelJustMoved = GUI.mouseHWheel ~= 0

    GUI.keyboardChar = gfxGetChar()

    GUI.windowWidth = gfx.w
    GUI.windowHeight = gfx.h

    GUI.windowWidthChange = GUI.windowWidth - GUI.previousWindowWidth
    GUI.windowWidthJustChanged = GUI.windowWidth ~= GUI.previousWindowWidth
    GUI.windowHeightChange = GUI.windowHeight - GUI.previousWindowHeight
    GUI.windowHeightJustChanged = GUI.windowHeight ~= GUI.previousWindowHeight
    GUI.windowWasJustResized = GUI.windowWidthJustChanged or GUI.windowHeightJustChanged

    GUI.mouseXChange = GUI.mouseX - GUI.previousMouseX
    GUI.mouseXJustChanged = GUI.mouseX ~= GUI.previousMouseX
    GUI.mouseYChange = GUI.mouseY - GUI.previousMouseY
    GUI.mouseYJustChanged = GUI.mouseY ~= GUI.previousMouseY
    GUI.mouseJustMoved = GUI.mouseXJustChanged or GUI.mouseYJustChanged

    updateMouseButtonState(GUI.leftMouseButton)
    updateMouseButtonState(GUI.middleMouseButton)
    updateMouseButtonState(GUI.rightMouseButton)
    updateMouseButtonState(GUI.shiftKey)
    updateMouseButtonState(GUI.controlKey)
    updateMouseButtonState(GUI.windowsKey)
    updateMouseButtonState(GUI.altKey)
end
local function updateGUIPreviousStates()
    GUI.previousMouseCap = GUI.mouseCap
    GUI.previousMouseX = GUI.mouseX
    GUI.previousMouseY = GUI.mouseY
    GUI.previousWindowWidth = GUI.windowWidth
    GUI.previousWindowHeight = GUI.windowHeight

    updateMouseButtonPreviousState(GUI.leftMouseButton)
    updateMouseButtonPreviousState(GUI.middleMouseButton)
    updateMouseButtonPreviousState(GUI.rightMouseButton)
    updateMouseButtonPreviousState(GUI.shiftKey)
    updateMouseButtonPreviousState(GUI.controlKey)
    updateMouseButtonPreviousState(GUI.windowsKey)
    updateMouseButtonPreviousState(GUI.altKey)
end

local currentTime = reaperTimePrecise()
local previousTime = currentTime
function GUI.run()
    local timer = reaperTimePrecise()

    updateGUIStates()

    -- Pass through the space bar.
    if GUI.keyboardChar == 32 then reaperMainOnCommandEx(40044, 0, 0) end

    currentTime = reaperTimePrecise()
    local dt = currentTime - previousTime
    GUI.update(dt)
    previousTime = currentTime

    updateGUIPreviousStates()

    -- Keep the window open unless escape or the close button are pushed.
    if GUI.keyboardChar ~= 27 and GUI.keyboardChar ~= -1 then reaperDefer(GUI.run) end
    gfxUpdate()

    gfx.x = 1
    gfx.y = 1
    gfx.set(0.7, 0.7, 0.7, 1, 0)
    gfx.drawnumber(1 / (reaperTimePrecise() - timer), 1)
end

return GUI