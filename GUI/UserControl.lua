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
local Toggle = require("GUI.Toggle")
local TrackedNumber = require("GUI.TrackedNumber")

--==============================================================
--== Mouse =====================================================
--==============================================================

local MouseControl = Prototype:new{
    mouse = {},
    wasPressedInsideWidget = {},
    pressState = Toggle:new(),
    dragState = false,
    isAlreadyDragging = false,
    wasJustReleasedLastFrame = false,
    timeOfPreviousPress = 0
}

function MouseControl:isPressed(widget)
    local output = self.pressState
    if widget then return output and self.mouse:isInside(widget) end
    return output
end
function MouseControl:justPressed(widget)
    local output = self.pressState:justTurnedOn()
    if widget then return output and self.mouse:isInside(widget) end
    return output
end
function MouseControl:justReleased(widget)
    local output = self.pressState:justTurnedOff()
    if widget then return output and self.wasPressedInsideWidget[widget] end
    return output
end
function MouseControl:getTimeSincePreviousPress()
    if not self.timeOfPreviousPress then return nil end
    return reaper.time_precise() - self.timeOfPreviousPress
end
function MouseControl:justDoublePressed(widget)
    local timeSince = self:getTimeSincePreviousPress()
    if timeSince == nil then return false end
    local output = self:justPressed() and timeSince <= 0.5
    if widget then return output and self.mouse:isInside(widget) end
    return output
end
function MouseControl:justDragged(widget)
    local output = self.dragState
    if widget then return output and self.wasPressedInsideWidget[widget] end
    return output
end
function MouseControl:justStartedDragging(widget)
    local output = self.dragState and not self.isAlreadyDragging
    if widget then return output and self.wasPressedInsideWidget[widget] end
    return output
end
function MouseControl:justStoppedDragging(widget)
    local output = self:justReleased() and self.isAlreadyDragging
    if widget then return output and self.wasPressedInsideWidget[widget] end
    return output
end

function MouseControl:update(state)
    local widgets = self.mouse:getWidgets()

    if self:justPressed() then self.timeOfPreviousPress = reaper.time_precise() end
    if self:justReleased() then self.isAlreadyDragging = false end

    self.wasJustReleasedLastFrame = self:justReleased()
    self.pressState:update(state)

    for i = 1, #widgets do
        local widget = widgets[i]
        if self.wasJustReleasedLastFrame then self.wasPressedInsideWidget[widget] = false end
        if self:justPressed(widget) then self.wasPressedInsideWidget[widget] = true end
    end

    if self.dragState then self.isAlreadyDragging = true end
    self.dragState = self.pressState:getState() and self.mouse:justMoved()
end

local function MouseButton(mouse, bitValue)
    local instance = MouseControl:new{ mouse = mouse }

    instance.bitValue = bitValue or 0

    function instance:update()
        MouseControl.update(instance, instance.mouse:getCap() & instance.bitValue == instance.bitValue)
    end

    return instance
end

local function Mouse()
    local self = {}

    local _x = TrackedNumber(0)
    local _y = TrackedNumber(0)
    local _cap = 0
    local _wheel = 0
    local _hWheel = 0
    local _widgets = {}

    function self:getWidgets()
        return _widgets
    end
    function self:getCap()
        return _cap
    end
    local _buttons = {
        left = MouseButton(self, 1),
        middle = MouseButton(self, 64),
        right = MouseButton(self, 2)
    }

    function self:getX() return _x:getValue() end
    function self:getY() return _y:getValue() end
    function self:getPreviousX() return _x:getPreviousValue() end
    function self:getPreviousY() return _y:getPreviousValue() end
    function self:getXChange() return _x:getChange() end
    function self:getYChange() return _y:getChange() end

    function self:getWheel() return _wheel end
    function self:getHWheel() return _hWheel end

    function self:setWidgets(widgets)
        _widgets = widgets
    end
    function self:getButtons()
        return _buttons
    end
    function self:update()
        _x:update(gfx.mouse_x)
        _y:update(gfx.mouse_y)
        _cap = gfx.mouse_cap

        _wheel = gfx.mouse_wheel / 120
        gfx.mouse_wheel = 0
        _hWheel = gfx.mouse_hwheel / 120
        gfx.mouse_hwheel = 0

        _buttons.left:update()
        _buttons.middle:update()
        _buttons.right:update()
    end
    function self:justMoved()
        return _x:justChanged() or _y:justChanged()
    end
    function self:wheelJustMoved()
        return _wheel ~= 0
    end
    function self:hWheelJustMoved()
        return _hWheel ~= 0
    end
    function self:wasPreviouslyInside(widget)
        return widget:pointIsInside(_x:getPreviousValue(), _y:getPreviousValue())
    end
    function self:isInside(widget)
        return widget:pointIsInside(_x:getValue(), _y:getValue())
    end
    function self:justEntered(widget)
        return self:isInside(widget) and not self:wasPreviouslyInside(widget)
    end
    function self:justLeft(widget)
        return not self:isInside(widget) and self:wasPreviouslyInside(widget)
    end

    return self
end

--==============================================================
--== Keyboard ==================================================
--==============================================================

local function KeyboardKey(mouse, character)
    local self = MouseControl(mouse)

    local _character = character or ""

    local _mouseControlUpdate = self.update
    function self:update()
        _mouseControlUpdate(self, gfx.getchar(characterTable[_character]) > 0)
    end

    return self
end

local function Keyboard(mouse)
    local self = {}

    local self.mouse = mouse
    local _currentCharacter = nil
    local _modifiers = {
        shift = MouseButton(self.mouse, 8),
        control = MouseButton(self.mouse, 4),
        windows = MouseButton(self.mouse, 32),
        alt = MouseButton(self.mouse, 16)
    }
    local _keys = {}

    function self:getCurrentCharacter() return _currentCharacter end
    function self:getModifiers() return _modifiers end
    function self:getKeys() return _keys end

    function self:createKey(character)
        _keys[character] = KeyboardKey(self.mouse, character)
    end
    function self:update()
        for name, key in pairs(_modifiers) do key:update() end
        for name, key in pairs(_keys) do key:update() end
        _currentCharacter = characterTableInverted[gfx.getchar()]
    end

    return self
end

local UserControl = { mouse = Mouse() }
UserControl.keyboard = Keyboard(UserControl.mouse)
return UserControl