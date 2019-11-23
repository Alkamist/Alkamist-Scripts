local reaper = reaper
local gfx = gfx
local pairs = pairs
local ipairs = ipairs

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

local mouseX = 0
local previousMouseX = 0
local mouseY = 0
local previousMouseY = 0
local mouseCap = 0
local previousMouseCap = 0
local mouseWheel = 0
local mouseHWheel = 0
local char = 0
local title = ""
local x = 0
local y = 0
local width = 0
local previousWidth = 0
local height = 0
local previousHeight = 0
local dock = 0

local MouseControl = {}
function MouseControl.new()
    local self = {}

    self.downState = false
    self.previousDownState = false
    self.wasJustReleasedLastFrame = false
    self.timeOfPreviousPress = nil

    return self
end
function MouseControl:update(state)
    if MouseControl.justPressed(self) then self.timeOfPreviousPress = reaper.time_precise() end
    self.wasJustReleasedLastFrame = MouseControl.justReleased(self)
    self.previousDownState = self.downState
    self.downState = state
end
function MouseControl:isDown()
    return self.downState
end
function MouseControl:justPressed()
    return self.downState and not self.previousDownState
end
function MouseControl:justReleased()
    return not self.downState and self.previousDownState
end
function MouseControl:justDoublePressed()
    local timeSince = MouseControl.getTimeSincePreviousPress(self)
    if timeSince == nil then return false end
    return MouseControl.justPressed(self) and timeSince <= 0.5
end
function MouseControl:getTimeSincePreviousPress()
    local timeOfPreviousPress = self.timeOfPreviousPress
    if not timeOfPreviousPress then return nil end
    return reaper.time_precise() - timeOfPreviousPress
end

local MouseButton = {}
function MouseButton:new(bitValue)
    local self = MouseControl.new()
    self.bitValue = bitValue or 0
    return self
end
function MouseButton:update()
    local bitValue = self.bitValue
    MouseControl.update(self, mouseCap & bitValue == bitValue)
end
local KeyboardKey = {}
function KeyboardKey:new(character)
    local self = MouseControl.new()
    self.character = character or ""
    return self
end
function KeyboardKey:update()
    MouseControl.update(self, gfx.getchar(characterTable[self.character]) > 0)
end

local mouseButtons = {
    left = MouseButton:new(1),
    middle = MouseButton:new(64),
    right = MouseButton:new(2)
}
local mouseModifiers = {
    shift = MouseButton:new(8),
    control = MouseButton:new(4),
    windows = MouseButton:new(32),
    alt = MouseButton:new(16)
}
local keyboardKeys = {}

local GUI = {
    mouse = {},
    keyboard = {},
    window = {}
}
function GUI.onResize(widthChange, heightChange) end
function GUI.onTextInput(char) end
function GUI.onKeyPress(x, y, key) end
function GUI.onKeyRelease(x, y, key) end
function GUI.onMouseMove(xChange, yChange) end
function GUI.onMouseWheel(ticks) end
function GUI.onMouseHWheel(ticks) end
function GUI.onMousePress(x, y, button) end
function GUI.onMouseRelease(x, y, button) end

--[[function GUI.getNewImageBuffer()
    for i = 0, 1023 do
        if not self.bufferIsUsed[i] then
            self.bufferIsUsed[i] = true
            return i
        end
    end
end]]--
function GUI.mouse.getX() return mouseX end
function GUI.mouse.getY() return mouseY end
function GUI.mouse.isDown(buttonName) return MouseControl.isDown(mouseButtons[buttonName]) end
function GUI.keyboard.isDown(keyName)
    local mouseModifier = mouseModifiers[keyName]
    local keyboardKey = keyboardKeys[keyName]
    if mouseModifier then
        return MouseControl.isDown(mouseModifier)
    elseif keyboardKey then
        return MouseControl.isDown(keyboardKey)
    end
end
function GUI.keyboard.trackKey(character)
    keyboardKeys[character] = KeyboardKey:new(character)
end
function GUI.window.getX() return x end
function GUI.window.getY() return y end
function GUI.window.getWidth() return width end
function GUI.window.getHeight() return height end
function GUI.initialize(parameters)
    local parameters = parameters or {}
    title = parameters.title or title or ""
    x = parameters.x or x or 0
    y = parameters.y or y or 0
    width = parameters.width or width  or 0
    height = parameters.height or height or 0
    dock = parameters.dock or dock or 0
    gfx.init(title, width, height, dock, x, y)
end
function GUI.run()
    width = gfx.w
    height = gfx.h
    mouseX = gfx.mouse_x
    mouseY = gfx.mouse_y
    mouseCap = gfx.mouse_cap
    mouseWheel = gfx.mouse_wheel / 120
    gfx.mouse_wheel = 0
    mouseHWheel = gfx.mouse_hwheel / 120
    gfx.mouse_hwheel = 0

    char = characterTableInverted[gfx.getchar()]
    if char == "Space" then reaper.Main_OnCommandEx(40044, 0, 0) end

    -- Handle window resizing.
    if (width ~= previousWidth or height ~= previousHeight) then GUI.onResize(width - previousWidth, height - previousHeight) end

    -- Handle keyboard input.
    if char then GUI.onTextInput(char) end
    for k, v in pairs(mouseModifiers) do
        MouseButton.update(v)
        if MouseControl.justPressed(v) then GUI.onKeyPress(mouseX, mouseY, k) end
        if MouseControl.justReleased(v) then GUI.onMouseRelease(mouseX, mouseY, k) end
    end
    for k, v in pairs(keyboardKeys) do
        KeyboardKey.update(v)
        if MouseControl.justPressed(v) then GUI.onKeyPress(mouseX, mouseY, k) end
        if MouseControl.justReleased(v) then GUI.onMouseRelease(mouseX, mouseY, k) end
    end

    -- Handle mouse input.
    if (mouseX ~= previousMouseX or mouseY ~= previousMouseY) then GUI.onMouseMove(mouseX - previousMouseX, mouseY - previousMouseY) end
    if mouseWheel ~= 0 then GUI.onMouseWheel(mouseWheel) end
    if mouseHWheel ~= 0 then GUI.onMouseHWheel(mouseHWheel) end
    for k, v in pairs(mouseButtons) do
        MouseButton.update(v)
        if MouseControl.justPressed(v) then GUI.onMousePress(mouseX, mouseY, k) end
        if MouseControl.justReleased(v) then GUI.onMouseRelease(mouseX, mouseY, k) end
    end

    if char ~= "Escape" and char ~= "Close" then reaper.defer(GUI.run) end
    gfx.update()

    previousWidth = width
    previousHeight = height
    previousMouseX = mouseX
    previousMouseY = mouseY
end

return GUI