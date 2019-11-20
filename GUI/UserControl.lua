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

local Mouse = {}
local _widgets = {}
local _mouseCap = 0

local function MouseControl()
    local self = {}

    local _wasPressedInsideWidget = {}
    local _pressState = Toggle:new()
    local _isAlreadyDragging = false
    local _wasJustReleasedLastFrame = false
    local _timeOfPreviousPress = nil
    local _justDragged = false

    function self:getTimeSincePreviousPress()
        if not _timeOfPreviousPress then return nil end
        return reaper.time_precise() - _timeOfPreviousPress
    end
    function self:isPressed() return _pressState:getState() end
    function self:justPressed() return _pressState:justTurnedOn() end
    function self:justReleased() return _pressState:justTurnedOff() end
    function self:justDoublePressed()
        local timeSince = self:getTimeSincePreviousPress()
        if timeSince == nil then return false end
        return self:justPressed() and timeSince <= 0.5
    end
    function self:justDragged() return _justDragged end
    function self:isAlreadyDragging() return _isAlreadyDragging end
    function self:justStartedDragging() return _justDragged and not _isAlreadyDragging end
    function self:justStoppedDragging() return self:justReleased() and _isAlreadyDragging end

    function self:isPressedInWidget(widget) return self:isPressed() and Mouse:isInsideWidget(widget) end
    function self:justPressedWidget(widget) return self:justPressed() and Mouse:isInsideWidget(widget) end
    function self:justReleasedWidget(widget) return self:justReleased() and _wasPressedInsideWidget[widget] end
    function self:justDoublePressedWidget(widget) return self:justDoublePressed() and Mouse:isInsideWidget(widget) end
    function self:justDraggedWidget(widget) return _justDragged and _wasPressedInsideWidget[widget] end
    function self:justStartedDraggingWidget(widget) return _justDragged and not _isAlreadyDragging and _wasPressedInsideWidget[widget] end
    function self:justStoppedDraggingWidget(widget) return self:justReleased() and _isAlreadyDragging and _wasPressedInsideWidget[widget] end
    function self:updateWidgetPressState(widget)
        if _wasJustReleasedLastFrame then _wasPressedInsideWidget[widget] = false end
        if self:justPressedWidget(widget) then _wasPressedInsideWidget[widget] = true end
        local childWidgets = widget:getChildWidgets()
        if childWidgets then
            for i = 1, #childWidgets do
                self:updateWidgetPressState(childWidgets[i])
            end
        end
    end
    function self:update(state)
        if self:justPressed() then _timeOfPreviousPress = reaper.time_precise() end
        if self:justReleased() then _isAlreadyDragging = false end

        _wasJustReleasedLastFrame = self:justReleased()
        _pressState:update(state)

        local widgets = _widgets
        if widgets then
            for i = 1, #widgets do self:updateWidgetPressState(widgets[i]) end
        end

        if self:justDragged() then _isAlreadyDragging = true end
        _justDragged = self:isPressed() and Mouse:justMoved()
    end

    return self
end
local function MouseButton(bitValue)
    local self = {}

    local _bitValue = bitValue or 0

    local _originalUpdate = self.update
    function self:update()
        _originalUpdate(self, _mouseCap & _bitValue == _bitValue)
    end

    return self
end
local function KeyboardKey(character)
    local self = MouseControl()

    local _character = character or ""

    local _originalUpdate = self.update
    function self:update()
        _originalUpdate(self, gfx.getchar(characterTable[_character]) > 0)
    end

    return self
end

local _mouseWheel = 0
local _mouseHWheel = 0
local _mouseXTracker = TrackedNumber:new()
local _mouseYTracker = TrackedNumber:new()
local _mouseLeftButton = MouseButton(1)
local _mouseMiddleButton = MouseButton(64)
local _mouseRightButton = MouseButton(2)

function Mouse:getWidgets(widgets) return _widgets end
function Mouse:setWidgets(widgets) _widgets = widgets end
function Mouse:getLeftButton() return _mouseLeftButton end
function Mouse:getMiddleButton() return _mouseMiddleButton end
function Mouse:getRightButton() return _mouseRightButton end
function Mouse:getCap() return _mouseCap end
function Mouse:getX() return _mouseXTracker:getValue() end
function Mouse:setX(value) _mouseXTracker:setValue(value) end
function Mouse:getPreviousX() return _mouseXTracker:getPreviousValue() end
function Mouse:getXChange() return _mouseXTracker:getChange() end
function Mouse:xJustChanged() return _mouseXTracker:justChanged() end
function Mouse:getY() return _mouseYTracker:getValue() end
function Mouse:setY(value) _mouseYTracker:setValue(value) end
function Mouse:getPreviousY() return _mouseYTracker:getPreviousValue() end
function Mouse:getYChange() return _mouseYTracker:getChange() end
function Mouse:yJustChanged() return _mouseYTracker:justChanged() end
function Mouse:justMoved() return self:xJustChanged() or self:yJustChanged() end
function Mouse:getWheelValue() return _mouseWheel end
function Mouse:wheelJustMoved() return _mouseWheel ~= 0 end
function Mouse:getHWheelValue() return _mouseHWheel end
function Mouse:hWheelJustMoved() return _mouseHWheel ~= 0 end
function Mouse:wasPreviouslyInsideWidget(widget) return widget:pointIsInside(self:getPreviousX(), self:getPreviousY()) end
function Mouse:isInsideWidget(widget) return widget:pointIsInside(self:getX(), self:getY()) end
function Mouse:justEnteredWidget(widget) return self:isInsideWidget(widget) and not self:wasPreviouslyInsideWidget(widget) end
function Mouse:justLeftWidget(widget) return not self:isInsideWidget(widget) and self:wasPreviouslyInsideWidget(widget) end
function Mouse:update()
    _mouseXTracker:update(gfx.mouse_x)
    _mouseYTracker:update(gfx.mouse_y)
    _mouseCap = gfx.mouse_cap
    _mouseWheel = gfx.mouse_wheel / 120
    gfx.mouse_wheel = 0
    _mouseHWheel = gfx.mouse_hwheel / 120
    gfx.mouse_hwheel = 0
    _mouseLeftButton:update()
    _mouseMiddleButton:update()
    _mouseRightButton:update()
end

local Keyboard = {}

local _shiftKey = MouseButton(8)
local _controlKey = MouseButton(4)
local _windowsKey = MouseButton(32)
local _altKey = MouseButton(16)
local _keys = {}
local _currentCharacter = nil

function self:getCurrentCharacter() return _currentCharacter end
function self:getShiftKey() return _shiftKey end
function self:getControlKey() return _controlKey end
function self:getWindowsKey() return _windowsKey end
function self:getAltKey() return _altKey end
function self:getKey(character) return _keys[character] end
function self:createKey(character)
    _keys[character] = KeyboardKey(character)
end
function self:update()
    _shiftKey:update()
    _controlKey:update()
    _windowsKey:update()
    _altKey:update()
    for name, key in pairs(_keys) do key:update() end
    _currentCharacter = characterTableInverted[gfx.getchar()]
end

return {
    mouse = Mouse,
    keyboard = Keyboard
}