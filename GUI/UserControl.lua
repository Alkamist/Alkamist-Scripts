local reaper = reaper
local gfx = gfx

function invertTable(tbl)
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

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Proxy = require("Proxy")
local Toggle = require("GUI.Toggle")
local TrackedNumber = require("GUI.TrackedNumber")

--==============================================================
--== Mouse =====================================================
--==============================================================

local MouseControl = {}
MouseControl.mouse = {}
MouseControl.wasPressedInsideWidget = {}
MouseControl.pressState = Toggle:new()
MouseControl.dragState = false
MouseControl.isAlreadyDragging = false
MouseControl.wasJustReleasedLastFrame = false
MouseControl.timeOfPreviousPress = 0
MouseControl.timeSincePreviousPress = {
    get = function(self)
        if not self.timeOfPreviousPress then return nil end
        return reaper.time_precise() - self.timeOfPreviousPress
    end
}
MouseControl.isPressed = { from = "pressState.currentState" }
MouseControl.justPressed = { from = "pressState.justTurnedOn" }
MouseControl.justReleased = { from = "pressState.justTurnedOff" }
MouseControl.justDoublePressed = {
    get = function(self)
        local timeSince = self.timeSincePreviousPress
        if timeSince == nil then return false end
        return self.justPressed and timeSince <= 0.5
    end
}
MouseControl.justDragged = { from = "dragState" }
MouseControl.justStartedDragging = { get = function(self) return self.justDragged and not self.isAlreadyDragging end }
MouseControl.justStoppedDragging = { get = function(self) return self.justReleased and self.isAlreadyDragging end }
function MouseControl:isPressedInWidget(widget) return self.isPressed and self.mouse:isInsideWidget(widget) end
function MouseControl:justPressedWidget(widget) return self.justPressed and self.mouse:isInsideWidget(widget) end
function MouseControl:justReleasedWidget(widget) return self.justReleased and self.wasPressedInsideWidget[widget] end
function MouseControl:justDoublePressedWidget(widget) return self.justDoublePressed and self.mouse:isInsideWidget(widget) end
function MouseControl:justDraggedWidget(widget) return self.justDragged and self.wasPressedInsideWidget[widget] end
function MouseControl:justStartedDraggingWidget(widget) return self.justDragged and not self.isAlreadyDragging and self.wasPressedInsideWidget[widget] end
function MouseControl:justStoppedDragging(widget) return self.justReleased and self.isAlreadyDragging and self.wasPressedInsideWidget[widget] end
function MouseControl:update(state)
    local widgets = self.mouse.widgets

    if self.justPressed then self.timeOfPreviousPress = reaper.time_precise() end
    if self.justReleased then self.isAlreadyDragging = false end

    self.wasJustReleasedLastFrame = self.justReleased
    self.pressState:update(state)

    if widgets then
        for i = 1, #widgets do
            local widget = widgets[i]
            if self.wasJustReleasedLastFrame then self.wasPressedInsideWidget[widget] = false end
            if self.justPressedWidget(widget) then self.wasPressedInsideWidget[widget] = true end
        end
    end

    if self.dragState then self.isAlreadyDragging = true end
    self.dragState = self.isPressed and self.mouse:justMoved()
end
MouseControl = Proxy:createPrototype(MouseControl)

local MouseButton = {}
MouseButton.prototypes = { MouseControl }
MouseButton.bitValue = 0
function MouseButton:update()
    MouseControl.update(self, self.mouse.cap & self.bitValue == self.bitValue)
end
MouseButton = Proxy:createPrototype(MouseButton)

local Mouse = {}
Mouse.cap = 0
Mouse.wheel = 0
Mouse.hWheel = 0
Mouse.widgets = {}
Mouse.xTracker = TrackedNumber:new()
Mouse.x = { from = "xTracker.currentValue" }
Mouse.previousX = { from = "xTracker.previousValue" }
Mouse.xJustChanged = { from = "xTracker.justChanged" }
Mouse.xChange = { from = "xTracker.change" }
Mouse.yTracker = TrackedNumber:new()
Mouse.y = { from = "yTracker.currentValue" }
Mouse.previousY = { from = "yTracker.previousValue" }
Mouse.yJustChanged = { from = "yTracker.justChanged" }
Mouse.yChange = { from = "yTracker.change" }
Mouse.buttons = {
    left = MouseButton:new{ mouse = Mouse, bitValue = 1 },
    middle = MouseButton:new{ mouse = Mouse, bitValue = 64 },
    right = MouseButton:new{ mouse = Mouse, bitValue = 2 }
}
Mouse.justMoved = { get = function(self) return self.xJustChanged or self.yJustChanged end }
Mouse.wheelJustMoved = { get = function(self) return self.wheel ~= 0 end }
Mouse.hWheelJustMoved = { get = function(self) return self.hWheel ~= 0 end }
function Mouse:wasPreviouslyInsideWidget(widget) return widget:pointIsInside(self.previousX, self.previousY) end
function Mouse:isInsideWidget(widget) return widget:pointIsInside(self.x, self.y) end
function Mouse:justEntered(widget) return self:isInsideWidget(widget) and not self:wasPreviouslyInside(widget) end
function Mouse:justLeft(widget) return not self:isInsideWidget(widget) and self:wasPreviouslyInside(widget) end
function Mouse:update()
    self.xTracker:update(gfx.mouse_x)
    self.yTracker:update(gfx.mouse_y)
    self.cap = gfx.mouse_cap

    self.wheel = gfx.mouse_wheel / 120
    gfx.mouse_wheel = 0
    self.hWheel = gfx.mouse_hwheel / 120
    gfx.mouse_hwheel = 0

    self.buttons.left:update()
    self.buttons.middle:update()
    self.buttons.right:update()
end
Mouse = Proxy:createPrototype(Mouse)

--==============================================================
--== Keyboard ==================================================
--==============================================================

local KeyboardKey = {}
KeyboardKey.prototypes = { MouseControl }
KeyboardKey.character = ""
function KeyboardKey:update()
    MouseControl.update(self, gfx.getchar(characterTable[self.character]) > 0)
end
KeyboardKey = Proxy:createPrototype(KeyboardKey)

local Keyboard = {}
Keyboard.mouse = {}
Keyboard.currentCharacter = nil
Keyboard.modifiers = {
    shift = MouseButton:new{ mouse = Keyboard.mouse, bitValue = 8 },
    control = MouseButton:new{ mouse = Keyboard.mouse, bitValue = 4 },
    windows = MouseButton:new{ mouse = Keyboard.mouse, bitValue = 32 },
    alt = MouseButton:new{ mouse = Keyboard.mouse, bitValue = 16 }
}
Keyboard.keys = {}
function Keyboard:createKey(character)
    self.keys[character] = KeyboardKey:new{ mouse = self.mouse, character = character }
end
function Keyboard:update()
    for name, key in pairs(self.modifiers) do key:update() end
    for name, key in pairs(self.keys) do key:update() end
    self.currentCharacter = characterTableInverted[gfx.getchar()]
end
Keyboard = Proxy:createPrototype(Keyboard)

local UserControl = { mouse = Mouse:new() }
UserControl.keyboard = Keyboard:new{ mouse = UserControl.mouse }
return UserControl