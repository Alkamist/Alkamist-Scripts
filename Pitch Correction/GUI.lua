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
    mouseHWheel = 0,

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

    leftMouseButtonIsPressed = false,
    leftMouseButtonWasPreviouslyPressed = false,
    leftMouseButtonJustPressed = false,
    leftMouseButtonJustReleased = false,
    leftMouseButtonWasPressedInsideWidget = {},

    middleMouseButtonIsPressed = false,
    middleMouseButtonWasPreviouslyPressed = false,
    middleMouseButtonJustPressed = false,
    middleMouseButtonJustReleased = false,
    middleMouseButtonWasPressedInsideWidget = {},

    rightMouseButtonIsPressed = false,
    rightMouseButtonWasPreviouslyPressed = false,
    rightMouseButtonJustPressed = false,
    rightMouseButtonJustReleased = false,
    rightMouseButtonWasPressedInsideWidget = {},

    shiftKeyIsPressed = false,
    shiftKeyWasPreviouslyPressed = false,
    shiftKeyJustPressed = false,
    shiftKeyJustReleased = false,
    shiftKeyWasPressedInsideWidget = {},

    controlKeyIsPressed = false,
    controlKeyWasPreviouslyPressed = false,
    controlKeyJustPressed = false,
    controlKeyJustReleased = false,
    controlKeyWasPressedInsideWidget = {},

    windowsKeyIsPressed = false,
    windowsKeyWasPreviouslyPressed = false,
    windowsKeyJustPressed = false,
    windowsKeyJustReleased = false,
    windowsKeyWasPressedInsideWidget = {},

    altKeyJustPressed = false,
    altKeyWasPreviouslyPressed = false,
    altKeyJustPressed = false,
    altKeyJustReleased = false,
    altKeyWasPressedInsideWidget = {},

    widgets = {}
}

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

function GUI.addWidget(widget)
    GUI.widgets[#GUI.widgets + 1] = widget
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

local function updateGUIStates()
    GUI.mouseCap = gfx.mouse_cap
    GUI.mouseX = gfx.mouse_x
    GUI.mouseY = gfx.mouse_y
    GUI.mouseWheel = gfx.mouse_wheel / 120
    gfx.mouse_wheel = 0
    GUI.mouseHWheel = gfx.mouse_hwheel / 120
    gfx.mouse_hwheel = 0

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

    GUI.leftMouseButtonIsPressed = GUI.mouseCap & 1 == 1
    GUI.middleMouseButtonIsPressed = GUI.mouseCap & 64 == 64
    GUI.rightMouseButtonIsPressed = GUI.mouseCap & 2 == 2
    GUI.shiftKeyIsPressed = GUI.mouseCap & 8 == 8
    GUI.controlKeyIsPressed = GUI.mouseCap & 4 == 4
    GUI.windowsKeyIsPressed = GUI.mouseCap & 32 == 32
    GUI.altKeyIsPressed = GUI.mouseCap & 16 == 16

    GUI.leftMouseButtonJustPressed = GUI.leftMouseButtonIsPressed and not GUI.leftMouseButtonWasPreviouslyPressed
    GUI.middleMouseButtonJustPressed = GUI.middleMouseButtonIsPressed and not GUI.middleMouseButtonWasPreviouslyPressed
    GUI.rightMouseButtonJustPressed = GUI.rightMouseButtonIsPressed and not GUI.rightMouseButtonWasPreviouslyPressed
    GUI.shiftKeyJustPressed = GUI.shiftKeyIsPressed and not GUI.shiftKeyWasPreviouslyPressed
    GUI.controlKeyJustPressed = GUI.controlKeyIsPressed and not GUI.controlKeyWasPreviouslyPressed
    GUI.windowsKeyJustPressed = GUI.windowsKeyIsPressed and not GUI.windowsKeyWasPreviouslyPressed
    GUI.altKeyJustPressed = GUI.altKeyIsPressed and not GUI.altKeyWasPreviouslyPressed

    GUI.leftMouseButtonJustReleased = not GUI.leftMouseButtonIsPressed and GUI.leftMouseButtonWasPreviouslyPressed
    GUI.middleMouseButtonJustReleased = not GUI.middleMouseButtonIsPressed and GUI.middleMouseButtonWasPreviouslyPressed
    GUI.rightMouseButtonJustReleased = not GUI.rightMouseButtonIsPressed and GUI.rightMouseButtonWasPreviouslyPressed
    GUI.shiftKeyJustReleased = not GUI.shiftKeyIsPressed and GUI.shiftKeyWasPreviouslyPressed
    GUI.controlKeyJustReleased = not GUI.controlKeyIsPressed and GUI.controlKeyWasPreviouslyPressed
    GUI.windowsKeyJustReleased = not GUI.windowsKeyIsPressed and GUI.windowsKeyWasPreviouslyPressed
    GUI.altKeyJustReleased = not GUI.altKeyIsPressed and GUI.altKeyWasPreviouslyPressed

    GUI.leftMouseButtonJustDragged = GUI.leftMouseButtonIsPressed and GUI.mouseJustMoved
    GUI.middleMouseButtonJustDragged = GUI.middleMouseButtonIsPressed and GUI.mouseJustMoved
    GUI.rightMouseButtonJustDragged = GUI.rightMouseButtonIsPressed and GUI.mouseJustMoved
    GUI.shiftKeyJustDragged = GUI.shiftKeyIsPressed and GUI.mouseJustMoved
    GUI.controlKeyJustDragged = GUI.controlKeyIsPressed and GUI.mouseJustMoved
    GUI.windowsKeyJustDragged = GUI.windowsKeyIsPressed and GUI.mouseJustMoved
    GUI.altKeyJustDragged = GUI.altKeyIsPressed and GUI.mouseJustMoved
end
local function updateGUIPreviousStates()
    GUI.previousMouseCap = GUI.mouseCap
    GUI.previousMouseX = GUI.mouseX
    GUI.previousMouseY = GUI.mouseY
    GUI.previousWindowWidth = GUI.windowWidth
    GUI.previousWindowHeight = GUI.windowHeight

    GUI.leftMouseButtonWasPreviouslyPressed = GUI.leftMouseButtonIsPressed
    GUI.middleMouseButtonWasPreviouslyPressed = GUI.middleMouseButtonIsPressed
    GUI.rightMouseButtonWasPreviouslyPressed = GUI.rightMouseButtonIsPressed
    GUI.shiftKeyWasPreviouslyPressed = GUI.shiftKeyIsPressed
    GUI.controlKeyWasPreviouslyPressed = GUI.controlKeyIsPressed
    GUI.windowsKeyWasPreviouslyPressed = GUI.windowsKeyIsPressed
    GUI.altKeyWasPreviouslyPressed = GUI.altKeyIsPressed
end
local function processWidgetEvents(dt)
    local widgets = GUI.widgets

    for i = 1, #widgets do
        local widget = widgets[i]
        local mouseIsInsideWidget = widget:pointIsInside(GUI.mouseX, GUI.mouseY)

        widget:onUpdate(dt)

        if GUI.windowWasJustResized then widget:onWindowJustResized() end

        if GUI.leftMouseButtonJustPressed and mouseIsInsideWidget then
            GUI.leftMouseButtonWasPressedInsideWidget[widget] = true
            widget:onLeftMouseButtonJustPressed()
        end
        if GUI.leftMouseButtonJustReleased and GUI.leftMouseButtonWasPressedInsideWidget[widget] then
            widget:onLeftMouseButtonJustReleased()
            GUI.leftMouseButtonWasPressedInsideWidget[widget] = false
        end
        if GUI.leftMouseButtonJustDragged and GUI.leftMouseButtonWasPressedInsideWidget[widget] then
            widget:onLeftMouseButtonJustDragged()
        end

        if GUI.middleMouseButtonJustPressed and mouseIsInsideWidget then
            GUI.middleMouseButtonWasPressedInsideWidget[widget] = true
            widget:onMiddleMouseButtonJustPressed()
        end
        if GUI.middleMouseButtonJustReleased and GUI.middleMouseButtonWasPressedInsideWidget[widget] then
            widget:onMiddleMouseButtonJustReleased()
            GUI.middleMouseButtonWasPressedInsideWidget[widget] = false
        end
        if GUI.middleMouseButtonJustDragged and GUI.middleMouseButtonWasPressedInsideWidget[widget] then
            widget:onMiddleMouseButtonJustDragged()
        end

        if GUI.rightMouseButtonJustPressed and mouseIsInsideWidget then
            GUI.rightMouseButtonWasPressedInsideWidget[widget] = true
            widget:onRightMouseButtonJustPressed()
        end
        if GUI.rightMouseButtonJustReleased and GUI.rightMouseButtonWasPressedInsideWidget[widget] then
            widget:onRightMouseButtonJustReleased()
            GUI.rightMouseButtonWasPressedInsideWidget[widget] = false
        end
        if GUI.rightMouseButtonJustDragged and GUI.rightMouseButtonWasPressedInsideWidget[widget] then
            widget:onRightMouseButtonJustDragged()
        end

        if GUI.shiftKeyJustPressed and mouseIsInsideWidget then
            GUI.shiftKeyWasPressedInsideWidget[widget] = true
            widget:onShiftKeyJustPressed()
        end
        if GUI.shiftKeyJustReleased and GUI.shiftKeyWasPressedInsideWidget[widget] then
            widget:onShiftKeyJustReleased()
            GUI.shiftKeyWasPressedInsideWidget[widget] = false
        end
        if GUI.shiftKeyJustDragged and GUI.shiftKeyWasPressedInsideWidget[widget] then
            widget:onShiftKeyJustDragged()
        end

        if GUI.controlKeyJustPressed and mouseIsInsideWidget then
            GUI.controlKeyWasPressedInsideWidget[widget] = true
            widget:onControlKeyJustPressed()
        end
        if GUI.controlKeyJustReleased and GUI.controlKeyWasPressedInsideWidget[widget] then
            widget:onControlKeyJustReleased()
            GUI.controlKeyWasPressedInsideWidget[widget] = false
        end
        if GUI.controlKeyJustDragged and GUI.controlKeyWasPressedInsideWidget[widget] then
            widget:onControlKeyJustDragged()
        end

        if GUI.windowsKeyJustPressed and mouseIsInsideWidget then
            GUI.windowsKeyWasPressedInsideWidget[widget] = true
            widget:onWindowsKeyJustPressed()
        end
        if GUI.windowsKeyJustReleased and GUI.windowsKeyWasPressedInsideWidget[widget] then
            widget:onWindowsKeyJustReleased()
            GUI.windowsKeyWasPressedInsideWidget[widget] = false
        end
        if GUI.windowsKeyJustDragged and GUI.windowsKeyWasPressedInsideWidget[widget] then
            widget:onWindowsKeyJustDragged()
        end

        if GUI.altKeyJustPressed and mouseIsInsideWidget then
            GUI.altKeyWasPressedInsideWidget[widget] = true
            widget:onAltKeyJustPressed()
        end
        if GUI.altKeyJustReleased and GUI.altKeyWasPressedInsideWidget[widget] then
            widget:onAltKeyJustReleased()
            GUI.altKeyWasPressedInsideWidget[widget] = false
        end
        if GUI.altKeyJustDragged and GUI.altKeyWasPressedInsideWidget[widget] then
            widget:onAltKeyJustDragged()
        end

        if GUI.keyboardChar then widget:onKeyTyped(GUI.keyboardChar) end
    end

    for i = 1, #widgets do
        local a, mode, dest = gfx.a, gfx.mode, gfx.dest
        widgets[i]:onDraw(dt)
        gfx.a, gfx.mode, gfx.dest = a, mode, dest
    end

    for i = 1, #widgets do widgets[i]:onEndUpdate(dt) end
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
    processWidgetEvents(dt)
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