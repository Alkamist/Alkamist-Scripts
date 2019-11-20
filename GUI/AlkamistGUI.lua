local reaper = reaper
local gfx = gfx
local pairs = pairs
local ipairs = ipairs

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Proxy = require("Proxy")

local function invertTable(tbl)
    local invertedTable = {}
    for key, value in pairs(tbl) do
        invertedTable[value] = key
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

local GUI = Proxy:new()

local MouseControl = {}
function MouseControl:new()
    local self = Proxy:new(MouseControl)

    self.wasPressedInsideWidget = {}
    self.isPressed = false
    self.previousPressState = false
    self.justPressed = { get = function(self) return self.isPressed and not self.previousPressState end }
    self.justReleased = { get = function(self) return not self.isPressed and self.previousPressState end }
    self.wasJustReleasedLastFrame = false
    self.justDoublePressed = {
        get = function(self)
            local timeSince = self.timeSincePreviousPress
            if timeSince == nil then return false end
            return self.justPressed and timeSince <= 0.5
        end
    }
    self.timeOfPreviousPress = nil
    self.timeSincePreviousPress = {
        get = function(self)
            local timeOfPreviousPress = self.timeOfPreviousPress
            if not timeOfPreviousPress then return nil end
            return reaper.time_precise() - timeOfPreviousPress
        end
    }
    self.justDragged = false
    self.isAlreadyDragging = false
    self.justStartedDragging = { get = function(self) return self.justDragged and not self.isAlreadyDragging end }
    self.justStoppedDragging = { get = function(self) return self.justReleased and self.isAlreadyDragging end }

    return self
end
function MouseControl:isPressedInWidget(widget)
    return self.isPressed and GUI:mouseIsInsideWidget(widget)
end
function MouseControl:justPressedWidget(widget)
    return self.justPressed and GUI:mouseIsInsideWidget(widget)
end
function MouseControl:justReleasedWidget(widget)
    return self.justReleased and self.wasPressedInsideWidget[widget]
end
function MouseControl:justDoublePressedWidget(widget)
    return self.justDoublePressed and GUI:mouseIsInsideWidget(widget)
end
function MouseControl:justDraggedWidget(widget)
    return self.justDragged and self.wasPressedInsideWidget[widget]
end
function MouseControl:justStartedDraggingWidget(widget)
    return self.justDragged and not self.isAlreadyDragging and self.wasPressedInsideWidget[widget]
end
function MouseControl:justStoppedDraggingWidget(widget)
    return self.justReleased and self.isAlreadyDragging and self.wasPressedInsideWidget[widget]
end
function MouseControl:updateWidgetPressState(widget)
    if self.wasJustReleasedLastFrame then self.wasPressedInsideWidget[widget] = false end
    if self:justPressedWidget(widget) then self.wasPressedInsideWidget[widget] = true end
    local childWidgets = widget.childWidgets
    if childWidgets then
        for _, childWidget in ipairs(childWidgets) do
            self:updateWidgetPressState(childWidget)
        end
    end
end
function MouseControl:update(state)
    if self.justPressed then self.timeOfPreviousPress = reaper.time_precise() end
    if self.justReleased then self.isAlreadyDragging = false end
    self.wasJustReleasedLastFrame = self.justReleased

    self.previousPressState = self.isPressed
    self.isPressed = state

    local widgets = GUI.widgets
    if widgets then
        for _, widget in ipairs(widgets) do
            self:updateWidgetPressState(widget)
        end
    end

    if self.justDragged then self.isAlreadyDragging = true end
    self.justDragged = self.isPressed and GUI.mouseJustMoved
end
local function MouseButton(bitValue)
    local self = MouseControl:new()

    local _bitValue = bitValue or 0

    local _originalUpdate = self.update
    function self:update()
        _originalUpdate(self, GUI.mouseCap & _bitValue == _bitValue)
    end

    return self
end
local function KeyboardKey(character)
    local self = MouseControl:new()

    local _character = character or ""

    local _originalUpdate = self.update
    function self:update()
        _originalUpdate(self, gfx.getchar(characterTable[_character]) > 0)
    end

    return self
end

GUI.mouseX = 0
GUI.previousMouseX = 0
GUI.mouseXChange = { get = function(self) return self.mouseX - self.previousMouseX end }
GUI.mouseXJustChanged = { get = function(self) return self.mouseX ~= self.previousMouseX end }
GUI.mouseY = 0
GUI.previousMouseY = 0
GUI.yChange = { get = function(self) return self.mouseY - self.previousMouseY end }
GUI.mouseYJustChanged = { get = function(self) return self.mouseY ~= self.previousMouseY end }
GUI.mouseJustMoved = { get = function(self) return self.mouseXJustChanged or self.mouseYJustChanged end }
GUI.mouseCap = 0
GUI.mouseWheel = 0
GUI.mouseWheelJustMoved = { get = function(self) return self.mouseWheel ~= 0 end }
GUI.mouseHWheel = 0
GUI.mouseHWheelJustMoved = { get = function(self) return self.mouseHWheel ~= 0 end }
GUI.leftMouseButton = MouseButton(1)
GUI.middleMouseButton = MouseButton(64)
GUI.rightMouseButton = MouseButton(2)
GUI.shiftKey = MouseButton(8)
GUI.controlKey = MouseButton(4)
GUI.windowsKey = MouseButton(32)
GUI.altKey = MouseButton(16)
GUI.keys = {}
GUI.title = ""
GUI.x = 0
GUI.y = 0
GUI.width = 0
GUI.previousWidth = 0
GUI.widthJustChanged = { get = function(self) return self.width ~= self.previousWidth end }
GUI.widthChange = { get = function(self) return self.width - self.previousWidth end }
GUI.height = 0
GUI.previousHeight = 0
GUI.heightJustChanged = { get = function(self) return self.height ~= self.previousHeight end }
GUI.heightChange = { get = function(self) return self.height - self.previousHeight end }
GUI.windowWasResized = { get = function(self) return self.heightJustChanged or self.widthJustChanged end }
GUI.dock = 0
GUI.backgroundColor = {
    value = { 0.0, 0.0, 0.0, 1.0, 0 },
    get = function(self, field) return field.value end,
    set = function(self, value, field)
        field.value = value
        gfx.clear = value[1] * 255 + value[2] * 255 * 256 + value[3] * 255 * 65536
    end
}
GUI.widgets = {}

function GUI:mouseIsInsideWidget(widget)
    return widget:pointIsInside(self.mouseX, self.mouseY)
end
function GUI:mouseWasPreviouslyInsideWidget(widget)
    return widget:pointIsInside(self.previousMouseX, self.previousMouseY)
end
function GUI:mouseJustEnteredWidget(widget)
    return self:mouseIsInsideWidget(widget) and not self:mouseWasPreviouslyInsideWidget(widget)
end
function GUI:mouseJustLeftWidget(widget)
    return not self:mouseIsInsideWidget(widget) and self:mouseWasPreviouslyInsideWidget(widget)
end
function GUI:createKey(character)
    self.keys[character] = KeyboardKey(character)
end
function GUI:widgetIsUsingBuffer(widget, buffer)
    if buffer == widget.drawBuffer then return true end
    local childWidgets = widget.childWidgets
    if childWidgets then
        for _, childWidget in ipairs(childWidgets) do
            if self:widgetIsUsingBuffer(childWidget, buffer) then
                return true
            end
        end
    end
    return false
end
function GUI:bufferIsUsed(buffer)
    local widgets = self.widgets
    for _, widget in ipairs(widgets) do
        if self:widgetIsUsingBuffer(widget, buffer) then
            return true
        end
    end
    return false
end
function GUI:getNewDrawBuffer()
    for i = 0, 1023 do
        if not self:bufferIsUsed(i) then return i end
    end
end
function GUI:initialize(parameters)
    local parameters = parameters or {}
    self.title = parameters.title or self.title or ""
    self.x = parameters.x or self.x or 0
    self.y = parameters.y or self.y or 0
    self.width = parameters.width or self.width  or 0
    self.height = parameters.height or self.height or 0
    self.dock = parameters.dock or self.dock or 0
    gfx.init(self.title, self.width, self.height, self.dock, self.x, self.y)
end
function GUI:run()
    local self = GUI
    self.previousWidth = self.width
    self.previousHeight = self.height
    self.width = gfx.w
    self.height = gfx.h
    self.previousMouseX = self.mouseX
    self.previousMouseY = self.mouseY
    self.mouseX = gfx.mouse_x
    self.mouseY = gfx.mouse_y
    self.mouseCap = gfx.mouse_cap
    self.mouseWheel = gfx.mouse_wheel / 120
    gfx.mouse_wheel = 0
    self.mouseHWheel = gfx.mouse_hwheel / 120
    gfx.mouse_hwheel = 0
    self.leftMouseButton:update()
    self.middleMouseButton:update()
    self.rightMouseButton:update()
    self.shiftKey:update()
    self.controlKey:update()
    self.windowsKey:update()
    self.altKey:update()
    for name, key in pairs(self.keys) do key:update() end
    local char = characterTableInverted[gfx.getchar()]
    self.currentCharacter = char

    if char == "Space" then reaper.Main_OnCommandEx(40044, 0, 0) end

    local widgets = self.widgets
    local numberOfWidgets = #widgets
    for i = 1, numberOfWidgets do widgets[i]:doBeginUpdate() end
    for i = 1, numberOfWidgets do widgets[i]:doUpdate() end
    for i = 1, numberOfWidgets do widgets[i]:doDrawToBuffer() end
    for i = 1, numberOfWidgets do widgets[i]:doDrawToParent() end
    for i = 1, numberOfWidgets do widgets[i]:doEndUpdate() end

    if char ~= "Escape" and char ~= "Close" then reaper.defer(self.run) end
    gfx.update()
end

return GUI