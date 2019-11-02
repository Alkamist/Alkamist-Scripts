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
local ToggleState = require("GFX.ToggleState")
local TrackedNumber = require("GFX.TrackedNumber")

--==============================================================
--== Mouse =====================================================
--==============================================================

local MouseControl = {}

function MouseControl:new(mouse)
    local self = setmetatable({}, { __index = self })

    self.mouse = mouse
    self.state = ToggleState:new(false)
    self.dragState = false
    self.isAlreadyDragging = false

    return self
end

function MouseControl:update(state)
    if self:justPressed() then self.timeOfPreviousPress = reaper.time_precise() end
    if self:justReleased() then self.isAlreadyDragging = false end

    self.state:update(state)

    if self.dragState then self.isAlreadyDragging = true end
    self.dragState = self.state.current and self.mouse:justMoved()
end

function MouseControl:isPressed()
    return self.state.current
end
function MouseControl:justPressed()
    return self.state.justTurnedOn
end
function MouseControl:justDoublePressed()
    local timeSince = self:getTimeSincePreviousPress()
    if timeSince == nil then return false end
    return self:justPressed() and timeSince <= 0.5
end
function MouseControl:justReleased()
    return self.state.justTurnedOff
end
function MouseControl:justDragged()
    return self.dragState
end
function MouseControl:justStartedDragging()
    return self.dragState and not self.isAlreadyDragging
end
function MouseControl:justStoppedDragging()
    return self:justReleased() and self.isAlreadyDragging
end
function MouseControl:getTimeSincePreviousPress()
    if not self.timeOfPreviousPress then return nil end
    return reaper.time_precise() - self.timeOfPreviousPress
end

local MouseButton = setmetatable({}, { __index = MouseControl })

function MouseButton:new(mouse, bitValue)
    local self = setmetatable(MouseControl:new(mouse), { __index = self })
    self.bitValue = bitValue
    return self
end
function MouseButton:update()
    MouseControl.update(self, self.mouse.cap & self.bitValue == self.bitValue)
end

local Mouse = {}

function Mouse:new()
    local self = setmetatable({}, { __index = self })

    self.xTracker = TrackedNumber:new(0)
    self.x = 0
    self.xChange = 0
    self.yTracker = TrackedNumber:new(0)
    self.y = 0
    self.yChange = 0
    self.cap = 0
    self.wheel = 0
    self.hWheel = 0

    self.left = MouseButton:new(self, 1)
    self.middle = MouseButton:new(self, 64)
    self.right = MouseButton:new(self, 2)

    return self
end

function Mouse:update()
    self.xTracker:update(gfx.mouse_x)
    self.x = self.xTracker.current
    self.xChange = self.xTracker.change
    self.yTracker:update(gfx.mouse_y)
    self.y = self.yTracker.current
    self.yChange = self.yTracker.change
    self.cap = gfx.mouse_cap

    self.wheel = gfx.mouse_wheel / 120
    gfx.mouse_wheel = 0
    self.hWheel = gfx.mouse_hwheel / 120
    gfx.mouse_hwheel = 0

    self.left:update()
    self.middle:update()
    self.right:update()
end
function Mouse:didInside(element, action)
    return action and element.isVisible and self:isInside(element)
end
function Mouse:justMoved()
    return self.x ~= self.xTracker.previous and self.y ~= self.yTracker.previous
end
function Mouse:wheelJustMoved()
    return self.wheel ~= 0
end
function Mouse:hWheelJustMoved()
    return self.hWheel ~= 0
end
function Mouse:wasPreviouslyInside(element)
    return element:pointIsInside(self.previousX, self.previousY)
end
function Mouse:isInside(element)
    return element:pointIsInside(self.x, self.y)
end
function Mouse:justEntered(element)
    return self:isInside(element) and not self:wasPreviouslyInside(element)
end
function Mouse:justLeft(element)
    return not self:isInside(element) and self:wasPreviouslyInside(element)
end

--==============================================================
--== Keyboard ==================================================
--==============================================================

local KeyboardKey = setmetatable({}, { __index = MouseControl })

function KeyboardKey:new(mouse, character)
    local self = setmetatable(MouseControl:new(mouse), { __index = self })
    self.character = character
    return self
end
function KeyboardKey:update()
    MouseControl.update(self, gfx.getchar(characterTable[self.character]) > 0)
end

local Keyboard = {}

function Keyboard:new(mouse)
    local self = setmetatable({}, { __index = self })

    self.mouse = mouse
    self.currentCharacter = nil
    self.modifiers = {
        shift = MouseButton:new(mouse, 8),
        control = MouseButton:new(mouse, 4),
        windows = MouseButton:new(mouse, 32),
        alt = MouseButton:new(mouse, 16)
    }
    self.keys = {}

    return self
end

function Keyboard:update()
    for name, key in pairs(self.modifiers) do key:update() end
    for name, key in pairs(self.keys) do key:update() end
    self.currentCharacter = characterTableInverted[gfx.getchar()]
end
function Keyboard:createKey(character)
    self.keys[character] = KeyboardKey:new(self.mouse, character)
end

local UserControl = {
    mouse = Mouse:new()
}
UserControl.keyboard = Keyboard:new(UserControl.mouse)

return UserControl