local reaper = reaper
local gfx = gfx

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

local Mouse = {}
local _widgets = {}
local _mouseCap = 0

local function MouseControl()
    local self = {}

    local _wasPressedInsideWidget = {}
    local _pressState = false
    local _previousPressState = false
    local _isAlreadyDragging = false
    local _wasJustReleasedLastFrame = false
    local _timeOfPreviousPress = nil
    local _justDragged = false

    function self:getTimeSincePreviousPress()
        if not _timeOfPreviousPress then return nil end
        return reaper.time_precise() - _timeOfPreviousPress
    end
    function self:isPressed() return _pressState end
    function self:justPressed() return _pressState and not _previousPressState end
    function self:justReleased() return not _pressState and _previousPressState end
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
        _previousPressState = _pressState
        _pressState = state

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
    local self = MouseControl()

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
local _mouseX = 0
local _previousMouseX = 0
local _mouseY = 0
local _previousMouseY = 0
local _mouseLeftButton = MouseButton(1)
local _mouseMiddleButton = MouseButton(64)
local _mouseRightButton = MouseButton(2)

function Mouse:getLeftButton() return _mouseLeftButton end
function Mouse:getMiddleButton() return _mouseMiddleButton end
function Mouse:getRightButton() return _mouseRightButton end
function Mouse:getCap() return _mouseCap end
function Mouse:getX() return _mouseX end
function Mouse:setX(value) _mouseX = value end
function Mouse:getPreviousX() return _previousMouseX end
function Mouse:getXChange() return _mouseX - _previousMouseX end
function Mouse:xJustChanged() return _mouseX ~= _previousMouseX end
function Mouse:getY() return _mouseY end
function Mouse:setY(value) _mouseY = value end
function Mouse:getPreviousY() return _previousMouseY end
function Mouse:getYChange() return _mouseY - _previousMouseY end
function Mouse:yJustChanged() return _mouseY ~= _previousMouseY end
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
    _previousMouseX = _mouseX
    _previousMouseY = _mouseY
    _mouseX = gfx.mouse_x
    _mouseY = gfx.mouse_y
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

function Keyboard:getCurrentCharacter() return _currentCharacter end
function Keyboard:getShiftKey() return _shiftKey end
function Keyboard:getControlKey() return _controlKey end
function Keyboard:getWindowsKey() return _windowsKey end
function Keyboard:getAltKey() return _altKey end
function Keyboard:getKey(character) return _keys[character] end
function Keyboard:createKey(character)
    _keys[character] = KeyboardKey(character)
end
function Keyboard:update()
    _shiftKey:update()
    _controlKey:update()
    _windowsKey:update()
    _altKey:update()
    for name, key in pairs(_keys) do key:update() end
    _currentCharacter = characterTableInverted[gfx.getchar()]
end

local GUI = {}

local _title = ""
local _x = 0
local _y = 0
local _width = 0
local _previousWidth = 0
local _height = 0
local _previousHeight = 0
local _dock = 0
local _backgroundColor = { 0.0, 0.0, 0.0, 1.0, 0 }
local _bufferIsUsed = {}

function GUI:getMouse() return Mouse end
function GUI:getKeyboard() return Keyboard end
function GUI:getWidgets() return _widgets end
function GUI:setWidgets(widgets)
    for i = 1, #widgets do
        _widgets[i] = widgets[i]
    end
    Mouse:setWidgets(widgets)
end
function GUI:getX() return _x end
function GUI:setX(value) _x = value end
function GUI:getY() return _y end
function GUI:setY(value) _y = value end
function GUI:getWidth() return _width end
function GUI:setWidth(value) _width = value end
function GUI:getPreviousWidth() return _previousWidth end
function GUI:getWidthChange() return _width - _previousWidth end
function GUI:widthJustChanged() return _width ~= _previousWidth end
function GUI:getHeight() return _height end
function GUI:setHeight(value) _height = value end
function GUI:getPreviousHeight() return _previousHeight end
function GUI:getHeightChange() return _height - _previousHeight end
function GUI:heightJustChanged() return _height ~= _previousHeight end
function GUI:windowWasResized() return self:heightJustChanged() or self:widthJustChanged() end
function GUI:getNewDrawBuffer()
    for i = 0, 1023 do
        if not _bufferIsUsed[i] then
            _bufferIsUsed[i] = true
            return i
        end
    end
end
function GUI:setBackgroundColor(color)
    _backgroundColor = color
    gfx.clear = color[1] * 255 + color[2] * 255 * 256 + color[3] * 255 * 65536
end
function GUI:initialize(parameters)
    local parameters = parameters or {}
    _title = parameters.title or _title or ""
    self:setX(parameters.x or self:getX() or 0)
    self:setY(parameters.y or self:getY() or 0)
    self:setWidth(parameters.width or self:getWidth() or 0)
    self:setHeight(parameters.height or self:getHeight() or 0)
    _dock = parameters.dock or _dock or 0
    gfx.init(_title, self:getWidth(), self:getHeight(), _dock, self:getX(), self:getY())
end
function GUI:run()
    _previousWidth = _width
    _previousHeight = _height
    _width = gfx.w
    _height = gfx.h
    Mouse:update()
    Keyboard:update()

    local char = Keyboard:getCurrentCharacter()
    if char == "Space" then reaper.Main_OnCommandEx(40044, 0, 0) end

    local widgets = _widgets
    local numberOfWidgets = #widgets
    for i = 1, numberOfWidgets do widgets[i]:doBeginUpdate() end
    for i = 1, numberOfWidgets do widgets[i]:doUpdate() end
    for i = 1, numberOfWidgets do widgets[i]:doDrawToBuffer() end
    for i = 1, numberOfWidgets do widgets[i]:doDrawToParent() end
    for i = 1, numberOfWidgets do widgets[i]:doEndUpdate() end

    if char ~= "Escape" and char ~= "Close" then reaper.defer(GUI.run) end
    gfx.update()
end

return GUI