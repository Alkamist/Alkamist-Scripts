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

local function MouseControl(mouse)
    local instance = {}

    local _mouse = mouse
    local _pressState = Toggle(false)
    local _dragState = false
    local _isAlreadyDragging = false
    local _wasJustReleasedLastFrame = false
    local _timeOfPreviousPress = nil
    local _wasPressedInsideWidget = {}

    function instance:isPressed(widget)
        local output = _pressState:getState()
        if widget then return output and _mouse:isInside(widget) end
        return output
    end
    function instance:justPressed(widget)
        local output = _pressState:justTurnedOn()
        if widget then return output and _mouse:isInside(widget) end
        return output
    end
    function instance:justReleased(widget)
        local output = _pressState:justTurnedOff()
        if widget then return output and _wasPressedInsideWidget[widget] end
        return output
    end
    function instance:getTimeSincePreviousPress()
        if not _timeOfPreviousPress then return nil end
        return reaper.time_precise() - _timeOfPreviousPress
    end
    function instance:justDoublePressed(widget)
        local timeSince = instance:getTimeSincePreviousPress()
        if timeSince == nil then return false end
        local output = instance:justPressed() and timeSince <= 0.5
        if widget then return output and _mouse:isInside(widget) end
        return output
    end
    function instance:justDragged(widget)
        local output = _dragState
        if widget then return output and _wasPressedInsideWidget[widget] end
        return output
    end
    function instance:justStartedDragging(widget)
        local output = _dragState and not _isAlreadyDragging
        if widget then return output and _wasPressedInsideWidget[widget] end
        return output
    end
    function instance:justStoppedDragging(widget)
        local output = instance:justReleased() and _isAlreadyDragging
        if widget then return output and _wasPressedInsideWidget[widget] end
        return output
    end

    function instance:update(state)
        local widgets = _mouse:getWidgets()

        if instance:justPressed() then _timeOfPreviousPress = reaper.time_precise() end
        if instance:justReleased() then _isAlreadyDragging = false end

        _wasJustReleasedLastFrame = instance:justReleased()
        _pressState:update(state)

        for i = 1, #widgets do
            local widget = widgets[i]
            if _wasJustReleasedLastFrame then _wasPressedInsideWidget[widget] = false end
            if instance:justPressed(widget) then _wasPressedInsideWidget[widget] = true end
        end

        if _dragState then _isAlreadyDragging = true end
        _dragState = _pressState:getState() and _mouse:justMoved()
    end

    return instance
end

local function MouseButton(mouse, bitValue)
    local instance = MouseControl(mouse)

    local _mouse = mouse
    local _bitValue = bitValue or 0

    local _mouseControlUpdate = instance.update
    function instance:update()
        _mouseControlUpdate(instance, _mouse:getCap() & _bitValue == _bitValue)
    end

    return instance
end

local function Mouse()
    local instance = {}

    local _x = TrackedNumber(0)
    local _y = TrackedNumber(0)
    local _cap = 0
    local _wheel = 0
    local _hWheel = 0
    local _widgets = {}

    function instance:getWidgets()
        return _widgets
    end
    function instance:getCap()
        return _cap
    end
    local _buttons = {
        left = MouseButton(instance, 1),
        middle = MouseButton(instance, 64),
        right = MouseButton(instance, 2)
    }

    function instance:getX() return _x:getValue() end
    function instance:getY() return _y:getValue() end
    function instance:getPreviousX() return _x:getPreviousValue() end
    function instance:getPreviousY() return _y:getPreviousValue() end
    function instance:getXChange() return _x:getChange() end
    function instance:getYChange() return _y:getChange() end

    function instance:setWidgets(widgets)
        _widgets = widgets
    end
    function instance:getButtons()
        return _buttons
    end
    function instance:update()
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
    function instance:justMoved()
        return _x:justChanged() or _y:justChanged()
    end
    function instance:wheelJustMoved()
        return _wheel ~= 0
    end
    function instance:hWheelJustMoved()
        return _hWheel ~= 0
    end
    function instance:wasPreviouslyInside(widget)
        return widget:pointIsInside(_x:getPreviousValue(), _y:getPreviousValue())
    end
    function instance:isInside(widget)
        return widget:pointIsInside(_x:getValue(), _y:getValue())
    end
    function instance:justEntered(widget)
        return instance:isInside(widget) and not instance:wasPreviouslyInside(widget)
    end
    function instance:justLeft(widget)
        return not instance:isInside(widget) and instance:wasPreviouslyInside(widget)
    end

    return instance
end

--==============================================================
--== Keyboard ==================================================
--==============================================================

local function KeyboardKey(mouse, character)
    local instance = MouseControl(mouse)

    local _character = character or ""

    local _mouseControlUpdate = instance.update
    function instance:update()
        _mouseControlUpdate(instance, gfx.getchar(characterTable[_character]) > 0)
    end

    return instance
end

local function Keyboard(mouse)
    local instance = {}

    local _mouse = mouse
    local _currentCharacter = nil
    local _modifiers = {
        shift = MouseButton(_mouse, 8),
        control = MouseButton(_mouse, 4),
        windows = MouseButton(_mouse, 32),
        alt = MouseButton(_mouse, 16)
    }
    local _keys = {}

    function instance:getCurrentCharacter() return _currentCharacter end
    function instance:getModifiers() return _modifiers end
    function instance:getKeys() return _keys end

    function instance:createKey(character)
        _keys[character] = KeyboardKey(_mouse, character)
    end
    function instance:update()
        for name, key in pairs(_modifiers) do key:update() end
        for name, key in pairs(_keys) do key:update() end
        _currentCharacter = characterTableInverted[gfx.getchar()]
    end

    return instance
end

local UserControl = { mouse = Mouse() }
UserControl.keyboard = Keyboard(UserControl.mouse)
return UserControl