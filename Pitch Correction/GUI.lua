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
local pairs = pairs

local GUI = {
    mouse = {
        justMoved = false,
        cap = 0,
        previousCap = 0,
        x = 0,
        previousX = 0,
        xChange = 0,
        xJustChanged = false,
        y = 0,
        previousY = 0,
        yChange = 0,
        yJustChanged = false,
        wheel = 0,
        wheelJustMoved = false,
        hWheel = 0,
        hWheelJustMoved = false,
        buttons = {}
    },
    keyboard = {
        char = nil,
        modifiers = {},
        keys = {}
    },
    window = {
        title = "",
        x = 0,
        y = 0,
        width = 0,
        previousWidth = 0,
        widthChange = 0,
        widthJustChanged = false,
        height = 0,
        previousHeight = 0,
        heightChange = 0,
        heightJustChanged = false,
        wasJustResized = false,
        dock = 0
    },
    widgets = {}
}

local function initializeMouseButton(bitValue)
    local self = {}
    self.bitValue = bitValue
    self._wasPressedInsideWidget = {}
    self._justPressedWidget = {}
    self._justReleasedWidget = {}
    self._justDraggedWidget = {}

    function self:wasPressedInsideWidget(widget) return self._wasPressedInsideWidget[widget] end
    function self:justPressedWidget(widget) return self._justPressedWidget[widget] end
    function self:justReleasedWidget(widget) return self._justReleasedWidget[widget] end
    function self:justDraggedWidget(widget) return self._justDraggedWidget[widget] end

    return self
end
local function updateMouseButtonState(self)
    local mouseX, mouseY = GUI.mouse.x, GUI.mouse.y

    self.isPressed = GUI.mouse.cap & self.bitValue == self.bitValue
    self.justPressed = self.isPressed and not self.wasPreviouslyPressed
    self.justReleased = not self.isPressed and self.wasPreviouslyPressed
    self.justDragged = self.isPressed and GUI.mouse.justMoved

    local widgets = GUI.widgets
    for i = 1, #widgets do
        local widget = widgets[i]

        if widget.pointIsInside then
            if widget:pointIsInside(mouseX, mouseY) and self.justPressed then
                self._wasPressedInsideWidget[widget] = true
            end

            self._justPressedWidget[widget] = self.justPressed and self._wasPressedInsideWidget[widget]
            self._justReleasedWidget[widget] = self.justReleased and self._wasPressedInsideWidget[widget]
            self._justDraggedWidget[widget] = self.justDragged and self._wasPressedInsideWidget[widget]

            if self.justReleased then self._wasPressedInsideWidget[widget] = false end
        end
    end
end
local function updateMouseButtonPreviousState(self)
    self.wasPreviouslyPressed = self.isPressed
end

GUI.mouse.buttons.left = initializeMouseButton(1)
GUI.mouse.buttons.middle = initializeMouseButton(64)
GUI.mouse.buttons.right = initializeMouseButton(2)
GUI.keyboard.modifiers.shift = initializeMouseButton(8)
GUI.keyboard.modifiers.control = initializeMouseButton(4)
GUI.keyboard.modifiers.windows = initializeMouseButton(32)
GUI.keyboard.modifiers.alt = initializeMouseButton(16)

local drawingFunctions = {}

function drawingFunctions:setColor(rOrColor, g, b)
    if type(rOrColor) == "number" then
        gfxSet(rOrColor, g, b, gfx.a or 1, gfx.mode or 0)
    else
        local alpha = rOrColor[4] or gfx.a or 1
        local blendMode = rOrColor[5] or gfx.mode or 0
        gfxSet(rOrColor[1], rOrColor[2], rOrColor[3], alpha, blendMode)
    end
end
function drawingFunctions:drawRectangle(x, y, w, h, filled)
    local x = x + self.xDrawOffset
    local y = y + self.yDrawOffset
    gfxRect(x, y, w, h, filled)
end
function drawingFunctions:drawLine(x, y, x2, y2, antiAliased)
    local x = x + self.xDrawOffset
    local y = y + self.yDrawOffset
    local x2 = x2 + self.xDrawOffset
    local y2 = y2 + self.yDrawOffset
    gfxLine(x, y, x2, y2, antiAliased)
end
function drawingFunctions:drawCircle(x, y, r, filled, antiAliased)
    local x = x + self.xDrawOffset
    local y = y + self.yDrawOffset
    gfxCircle(x, y, r, filled, antiAliased)
end
function drawingFunctions:drawString(str, x, y, x2, y2, flags)
    local x = x + self.xDrawOffset
    local y = y + self.yDrawOffset
    local x2 = x2 + self.xDrawOffset
    local y2 = y2 + self.yDrawOffset
    gfx.x = x
    gfx.y = y
    if flags then
        gfxDrawStr(str, flags, x2, y2)
    else
        gfxDrawStr(str)
    end
end
function drawingFunctions:setFont(fontName, fontSize)
    gfxSetFont(1, fontName, fontSize)
end
function drawingFunctions:measureString(str)
    return gfxMeasureStr(str)
end

function GUI.makeDrawable(widget)
    for k, v in pairs(drawingFunctions) do
        if widget[k] == nil then
            widget[k] = v
        end
    end
    return widget
end
function GUI.addWidget(widget)
    local widgets = GUI.widgets

    GUI.makeDrawable(widget)
    widget.mouse = GUI.mouse
    widget.keyboard = GUI.keyboard
    widget.window = GUI.window
    widget.xDrawOffset = widget.xDrawOffset or 0
    widget.yDrawOffset = widget.yDrawOffset or 0

    widgets[#widgets + 1] = widget
end
local function updateWidgets()
    local widgets = GUI.widgets
    for i = 1, #widgets do widgets[i]:update() end
    for i = 1, #widgets do widgets[i]:draw() end
end

function GUI.setBackgroundColor(r, g, b)
    gfx.clear = r * 255 + g * 255 * 256 + b * 255 * 65536
end
function GUI.initialize(title, width, height, dock, x, y)
    local title = title or GUI.window.title or ""
    local x = x or GUI.window.x or 0
    local y = y or GUI.window.y or 0
    local width = width or GUI.window.width  or 0
    local height = height or GUI.window.height or 0
    local dock = dock or GUI.window.dock or 0

    GUI.window.title = title
    GUI.window.x = x
    GUI.window.y = y
    GUI.window.width = width
    GUI.window.previousWidth = width
    GUI.window.height = height
    GUI.window.previousHeight = height
    GUI.window.dock = dock

    gfxInit(title, width, height, dock, x, y)
end

local function updateGUIStates()
    GUI.mouse.cap = gfx.mouse_cap
    GUI.mouse.x = gfx.mouse_x
    GUI.mouse.y = gfx.mouse_y
    GUI.mouse.wheel = gfx.mouse_wheel / 120
    gfx.mouse_wheel = 0
    GUI.mouse.hWheel = gfx.mouse_hwheel / 120
    gfx.mouse_hwheel = 0

    GUI.mouse.wheelJustMoved = GUI.mouse.wheel ~= 0
    GUI.mouse.hWheelJustMoved = GUI.mouse.hWheel ~= 0

    GUI.keyboard.char = gfxGetChar()

    GUI.window.width = gfx.w
    GUI.window.height = gfx.h

    GUI.window.widthChange = GUI.window.width - GUI.window.previousWidth
    GUI.window.widthJustChanged = GUI.window.width ~= GUI.window.previousWidth
    GUI.window.heightChange = GUI.window.height - GUI.window.previousHeight
    GUI.window.heightJustChanged = GUI.window.height ~= GUI.window.previousHeight
    GUI.window.wasJustResized = GUI.window.widthJustChanged or GUI.window.heightJustChanged

    GUI.mouse.xChange = GUI.mouse.x - GUI.mouse.previousX
    GUI.mouse.xJustChanged = GUI.mouse.x ~= GUI.mouse.previousX
    GUI.mouse.yChange = GUI.mouse.y - GUI.mouse.previousY
    GUI.mouse.yJustChanged = GUI.mouse.y ~= GUI.mouse.previousY
    GUI.mouse.justMoved = GUI.mouse.xJustChanged or GUI.mouse.yJustChanged

    updateMouseButtonState(GUI.mouse.buttons.left)
    updateMouseButtonState(GUI.mouse.buttons.middle)
    updateMouseButtonState(GUI.mouse.buttons.right)
    updateMouseButtonState(GUI.keyboard.modifiers.shift)
    updateMouseButtonState(GUI.keyboard.modifiers.control)
    updateMouseButtonState(GUI.keyboard.modifiers.windows)
    updateMouseButtonState(GUI.keyboard.modifiers.alt)
end
local function updateGUIPreviousStates()
    GUI.mouse.previousCap = GUI.mouse.cap
    GUI.mouse.previousX = GUI.mouse.x
    GUI.mouse.previousY = GUI.mouse.y
    GUI.window.previousWidth = GUI.window.width
    GUI.window.previousHeight = GUI.window.height

    updateMouseButtonPreviousState(GUI.mouse.buttons.left)
    updateMouseButtonPreviousState(GUI.mouse.buttons.middle)
    updateMouseButtonPreviousState(GUI.mouse.buttons.right)
    updateMouseButtonPreviousState(GUI.keyboard.modifiers.shift)
    updateMouseButtonPreviousState(GUI.keyboard.modifiers.control)
    updateMouseButtonPreviousState(GUI.keyboard.modifiers.windows)
    updateMouseButtonPreviousState(GUI.keyboard.modifiers.alt)
end

function GUI.run()
    local timer = reaperTimePrecise()

    updateGUIStates()

    -- Pass through the space bar.
    if GUI.keyboard.char == 32 then reaperMainOnCommandEx(40044, 0, 0) end

    updateWidgets()

    updateGUIPreviousStates()

    -- Keep the window open unless escape or the close button are pushed.
    if GUI.keyboard.char ~= 27 and GUI.keyboard.char ~= -1 then reaperDefer(GUI.run) end
    gfxUpdate()

    gfx.x = 1
    gfx.y = 1
    gfx.set(0.7, 0.7, 0.7, 1, 0)
    gfx.drawnumber(1 / (reaperTimePrecise() - timer), 1)
end

return GUI