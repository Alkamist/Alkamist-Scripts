local reaper = reaper
local gfx = gfx
local pairs = pairs

local function invertTable(t)
    local invertedTable = {}
    for k, v in pairs(t) do
        invertedTable[v] = k
    end
    return invertedTable
end
local characterTable = {
    ["Close"]     = -1,
    ["Backspace"] = 8,
    ["Tab"]       = 8,
    ["Enter"]     = 13,
    ["Escape"]    = 27,
    ["Space"]     = 32,
    ["Delete"]    = 127,
    ["Home"]      = 1752132965,
    ["End"]       = 6647396,
    ["Insert"]    = 6909555,
    ["Delete"]    = 6579564,
    ["PageUp"]    = 1885828464,
    ["PageDown"]  = 1885824110,
    ["Up"]        = 30064,
    ["Down"]      = 1685026670,
    ["Left"]      = 1818584692,
    ["Right"]     = 1919379572,
    ["F1"]        = 26161,
    ["F2"]        = 26162,
    ["F3"]        = 26163,
    ["F4"]        = 26164,
    ["F5"]        = 26165,
    ["F6"]        = 26166,
    ["F7"]        = 26167,
    ["F8"]        = 26168,
    ["F9"]        = 26169,
    ["F10"]       = 6697264,
    ["F11"]       = 6697265,
    ["F12"]       = 6697266,
    ["Control+a"] = 1,
    ["Control+b"] = 2,
    ["Control+c"] = 3,
    ["Control+d"] = 4,
    ["Control+e"] = 5,
    ["Control+f"] = 6,
    ["Control+g"] = 7,
    ["Control+h"] = 8,
    ["Control+i"] = 9,
    ["Control+j"] = 10,
    ["Control+k"] = 11,
    ["Control+l"] = 12,
    --["Control+m"] = 13,
    ["Control+n"] = 14,
    ["Control+o"] = 15,
    ["Control+p"] = 16,
    ["Control+q"] = 17,
    ["Control+r"] = 18,
    ["Control+s"] = 19,
    ["Control+t"] = 20,
    ["Control+u"] = 21,
    ["Control+v"] = 22,
    ["Control+w"] = 23,
    ["Control+x"] = 24,
    ["Control+y"] = 25,
    ["Control+z"] = 26,
    ["!"]         = 33,
    ["\""]        = 34,
    ["#"]         = 35,
    ["$"]         = 36,
    ["%"]         = 37,
    ["&"]         = 38,
    ["\'"]        = 39,
    ["("]         = 40,
    [")"]         = 41,
    ["*"]         = 42,
    ["+"]         = 43,
    [","]         = 44,
    ["."]         = 45,
    ["/"]         = 47,
    ["0"]         = 48,
    ["1"]         = 49,
    ["2"]         = 50,
    ["3"]         = 51,
    ["4"]         = 52,
    ["5"]         = 53,
    ["6"]         = 54,
    ["7"]         = 55,
    ["8"]         = 56,
    ["9"]         = 57,
    [":"]         = 58,
    [";"]         = 59,
    ["<"]         = 60,
    ["="]         = 61,
    [">"]         = 62,
    ["?"]         = 63,
    ["@"]         = 64,
    ["A"]         = 65,
    ["B"]         = 66,
    ["C"]         = 67,
    ["D"]         = 68,
    ["E"]         = 69,
    ["F"]         = 70,
    ["G"]         = 71,
    ["H"]         = 72,
    ["I"]         = 73,
    ["J"]         = 74,
    ["K"]         = 75,
    ["L"]         = 76,
    ["M"]         = 77,
    ["N"]         = 78,
    ["O"]         = 79,
    ["P"]         = 80,
    ["Q"]         = 81,
    ["R"]         = 82,
    ["S"]         = 83,
    ["T"]         = 84,
    ["U"]         = 85,
    ["V"]         = 86,
    ["W"]         = 87,
    ["X"]         = 88,
    ["Y"]         = 89,
    ["Z"]         = 90,
    ["%["]        = 91,
    ["\\"]        = 92,
    ["%]"]        = 93,
    ["^"]         = 94,
    ["_"]         = 95,
    ["`"]         = 96,
    ["a"]         = 97,
    ["b"]         = 98,
    ["c"]         = 99,
    ["d"]         = 100,
    ["e"]         = 101,
    ["f"]         = 102,
    ["g"]         = 103,
    ["h"]         = 104,
    ["i"]         = 105,
    ["j"]         = 106,
    ["k"]         = 107,
    ["l"]         = 108,
    ["m"]         = 109,
    ["n"]         = 110,
    ["o"]         = 111,
    ["p"]         = 112,
    ["q"]         = 113,
    ["r"]         = 114,
    ["s"]         = 115,
    ["t"]         = 116,
    ["u"]         = 117,
    ["v"]         = 118,
    ["w"]         = 119,
    ["x"]         = 120,
    ["y"]         = 121,
    ["z"]         = 122,
    ["{"]         = 123,
    ["|"]         = 124,
    ["}"]         = 125,
    ["~"]         = 126,
}
local characterTableInverted = invertTable(characterTable)

local GUI = {
    mouse = {
        cap = 0,
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
        justMoved = false,
        _isInsideWidget = {},
        _wasPreviouslyInsideWidget = {},
        buttons = {}
    },
    keyboard = {
        keys = {},
        modifiers = {},
        char = nil
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
        dock = 0,
        wasJustResized = false,
        widgets = {}
    }
}
local mouse = GUI.mouse
local buttons = mouse.buttons
local keyboard = GUI.keyboard
local modifiers = keyboard.modifiers
local keys = keyboard.keys
local window = GUI.window

local MouseControl = {}
function MouseControl.new()
    local self = {}

    self.isPressed = false
    self.wasPreviouslyPressed = false
    self.justPressed = false
    self.justReleased = false
    self.justDoublePressed = false
    self.justDragged = false
    self.justStartedDragging = false
    self.justStoppedDragging = false
    self.hasDraggedSincePress = false
    self.timeOfPreviousPress = nil
    self.timeSincePreviousPress = nil
    self._wasPressedInsideWidget = {}

    for k, v in pairs(MouseControl) do
        if k ~= "new" then
            self[k] = v
        end
    end
    return self
end
function MouseControl:wasPressedInsideWidget(widget)
    return self._wasPressedInsideWidget[widget]
end
function MouseControl:justDraggedWidget(widget)
    return self.justDragged and self._wasPressedInsideWidget[widget]
end
function MouseControl:justStartedDraggingWidget(widget)
    return self.justStartedDragging and self._wasPressedInsideWidget[widget]
end
function MouseControl:justStoppedDraggingWidget(widget)
    return self.justStoppedDragging and self._wasPressedInsideWidget[widget]
end
function MouseControl:updateWidgetBasedStates(widget)
    if mouse:isInsideWidget(widget) and self.justPressed then
        self._wasPressedInsideWidget[widget] = true
    end
    if self.justReleased then
        self._wasPressedInsideWidget[widget] = false
    end

    local childWidgets = widget.widgets
    if childWidgets then
        for i = 1, #childWidgets do
            self:updateWidgetBasedStates(childWidgets[i])
        end
    end
end
function MouseControl:update(state)
    if self.justPressed then self.timeOfPreviousPress = reaper.time_precise() end
    self.wasPreviouslyPressed = self.isPressed

    self.isPressed = state

    self.justPressed = self.isPressed and not self.wasPreviouslyPressed
    self.justReleased = not self.isPressed and self.wasPreviouslyPressed
    self.justDragged = self.isPressed and mouse.justMoved
    self.justStartedDragging = self.justDragged and not self.hasDraggedSincePress
    if self.justDragged then self.hasDraggedSincePress = true end
    self.justStoppedDragging = self.justReleased and self.hasDraggedSincePress
    if self.justReleased then self.hasDraggedSincePress = false end
    if self.timeOfPreviousPress then
        self.timeSincePreviousPress = reaper.time_precise() - self.timeOfPreviousPress
        self.justDoublePressed = self.justPressed and self.timeSincePreviousPress <= 0.5
    end

    local widgets = window.widgets
    for i = 1, #widgets do
        self:updateWidgetBasedStates(widgets[i])
    end
end

local MouseButton = {}
function MouseButton.new(bitValue)
    local self = MouseControl.new()
    self.bitValue = bitValue or 0
    self.update = MouseButton.update
    return self
end
function MouseButton:update()
    local bitValue = self.bitValue
    MouseControl.update(self, mouse.cap & bitValue == bitValue)
end

local KeyboardKey = {}
function KeyboardKey.new(character)
    local self = MouseControl.new()
    self.character = character or ""
    self.update = KeyboardKey.update
    return self
end
function KeyboardKey:update()
    local character = self.character
    MouseControl.update(self, gfx.getchar(characterTable[character]) > 0)
end

buttons.left = MouseButton.new(1)
buttons.middle = MouseButton.new(64)
buttons.right = MouseButton.new(2)
modifiers.shift = MouseButton.new(8)
modifiers.control = MouseButton.new(4)
modifiers.windows = MouseButton.new(32)
modifiers.alt = MouseButton.new(16)

function mouse:update()
    mouse.x = gfx.mouse_x
    mouse.y = gfx.mouse_y
    mouse.cap = gfx.mouse_cap
    mouse.wheel = gfx.mouse_wheel / 120
    gfx.mouse_wheel = 0
    mouse.hWheel = gfx.mouse_hwheel / 120
    gfx.mouse_hwheel = 0
    mouse.xChange = mouse.x - mouse.previousX
    mouse.xJustChanged = mouse.x ~= mouse.previousX
    mouse.yChange = mouse.y - mouse.previousY
    mouse.yJustChanged = mouse.y ~= mouse.previousY
    mouse.justMoved = mouse.xJustChanged or mouse.yJustChanged
    mouse.wheelJustMoved = mouse.wheel ~= 0
    mouse.hWheelJustMoved = mouse.hWheel ~= 0

    for k, v in pairs(mouse.buttons) do v:update() end
end
function mouse:updateWidgetBasedStates(widget)
    mouse._wasPreviouslyInsideWidget[widget] = mouse:isInsideWidget(widget)

    local childWidgets = widget.widgets
    if childWidgets then
        for i = 1, #childWidgets do
            mouse:updateWidgetBasedStates(childWidgets[i])
        end
    end
end
function mouse:endUpdate()
    local widgets = window.widgets
    local numberOfWidgets = #widgets
    for i = 1, numberOfWidgets do
        local widget = widgets[i]
        mouse:updateWidgetBasedStates(widget)
    end

    mouse.previousX = mouse.x
    mouse.previousY = mouse.y
end
function mouse:isInsideWidget(widget)
    return widget:pointIsInside(mouse.x, mouse.y)
end
function mouse:wasPreviouslyInsideWidget(widget)
    return mouse._wasPreviouslyInsideWidget[widget]
end
function mouse:justEnteredWidget(widget)
    return mouse:isInsideWidget(widget) and not mouse:wasPreviouslyInsideWidget(widget)
end
function mouse:justLeftWidget(widget)
    return not mouse:isInsideWidget(widget) and mouse:wasPreviouslyInsideWidget(widget)
end
function keyboard:update()
    for k, v in pairs(keyboard.modifiers) do v:update() end
    for k, v in pairs(keyboard.keys) do v:update() end
end
function keyboard:endUpdate() end
function keyboard:createKey(character)
    keys[character] = KeyboardKey.new(character)
end
function window:update()
    window.widthChange = window.width - window.previousWidth
    window.widthJustChanged = window.width ~= window.previousWidth
    window.heightChange = window.height - window.previousHeight
    window.heightJustChanged = window.height ~= window.previousHeight
    window.wasJustResized = window.widthJustChanged or window.heightJustChanged
end
function window:endUpdate()
    window.previousWidth = window.width
    window.previousHeight = window.height
end
function window:setBackgroundColor(r, g, b)
    gfx.clear = r * 255 + g * 255 * 256 + b * 255 * 65536
end
function GUI.window:initialize(parameters)
    local parameters = parameters or {}
    window.title = parameters.title or window.title or ""
    window.x = parameters.x or window.x or 0
    window.y = parameters.y or window.y or 0
    window.width = parameters.width or window.width  or 0
    window.height = parameters.height or window.height or 0
    window.dock = parameters.dock or window.dock or 0
    gfx.init(window.title, window.width, window.height, window.dock, window.x, window.y)
end

function GUI.run()
    local timer = reaper.time_precise()

    window:update()
    mouse:update()
    keyboard:update()

    local char = characterTableInverted[gfx.getchar()]
    keyboard.char = char
    if char == "Space" then reaper.Main_OnCommandEx(40044, 0, 0) end

    local widgets = window.widgets
    local numberOfWidgets = #widgets
    for i = 1, numberOfWidgets do widgets[i]:doUpdate() end
    for i = 1, numberOfWidgets do widgets[i]:doDraw() end
    for i = 1, numberOfWidgets do widgets[i]:doEndUpdate() end

    if char ~= "Escape" and char ~= "Close" then reaper.defer(GUI.run) end
    gfx.update()

    window:endUpdate()
    mouse:endUpdate()

    gfx.x = 1
    gfx.y = 1
    gfx.set(0.7, 0.7, 0.7, 1, 0)
    local fps = 1 / (reaper.time_precise() - timer)
    gfx.drawnumber(fps, 1)
end

return GUI