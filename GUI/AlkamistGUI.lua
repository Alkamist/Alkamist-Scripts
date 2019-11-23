local reaper = reaper
local gfx = gfx
local gfxSet = gfx.set
local gfxRect = gfx.rect
local gfxLine = gfx.line
local gfxCircle = gfx.circle
local gfxTriangle = gfx.triangle
local gfxRoundRect = gfx.roundrect
local gfxSetFont = gfx.setfont
local gfxMeasureStr = gfx.measurestr
local gfxDrawStr = gfx.drawstr
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

    self.pressState = false
    self.previousPressState = false
    self.wasJustReleasedLastFrame = false
    self.timeOfPreviousPress = nil

    return self
end
function MouseControl:update(state)
    if MouseControl.justPressed(self) then self.timeOfPreviousPress = reaper.time_precise() end
    self.wasJustReleasedLastFrame = MouseControl.justReleased(self)
    self.previousPressState = self.pressState
    self.pressState = state
end
function MouseControl:isPressed()
    return self.pressState
end
function MouseControl:justPressed()
    return self.pressState and not self.previousPressState
end
function MouseControl:justReleased()
    return not self.pressState and self.previousPressState
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

local GUI = {
    leftMouseButton = MouseButton:new(1),
    middleMouseButton = MouseButton:new(64),
    rightMouseButton = MouseButton:new(2),
    shiftKey = MouseButton:new(8),
    controlKey = MouseButton:new(4),
    windowsKey = MouseButton:new(32),
    altKey = MouseButton:new(16),
    keys = {}
}

--[[function GUI.getNewImageBuffer()
    for i = 0, 1023 do
        if not self.bufferIsUsed[i] then
            self.bufferIsUsed[i] = true
            return i
        end
    end
end]]--

function GUI.onUpdate() end
function GUI.onDraw() end
function GUI.onEndUpdate() end

function GUI.createKey(character) GUI.keys[character] = KeyboardKey:new(character) end
function GUI.getCurrentCharacter() return char end

function GUI.getMouseX() return mouseX end
function GUI.getPreviousMouseX() return previousMouseX end
function GUI.getMouseXChange() return mouseX - previousMouseX end
function GUI.mouseXJustChanged() return mouseX ~= previousMouseX end

function GUI.getMouseY() return mouseY end
function GUI.getPreviousMouseY() return previousMouseY end
function GUI.getMouseYChange() return mouseY - previousMouseY end
function GUI.mouseYJustChanged() return mouseY ~= previousMouseY end

function GUI.mouseJustMoved() return (mouseX ~= previousMouseX) or (mouseY ~= previousMouseY) end

function GUI.getMouseWheel() return mouseWheel end
function GUI.mouseWheelJustMoved() return mouseWheel ~= 0 end
function GUI.getMouseHWheel() return mouseHWheel end
function GUI.mouseHWheelJustMoved() return mouseHWheel ~= 0 end

function GUI.getWindowX() return x end
function GUI.getWindowY() return y end

function GUI.getWindowWidth() return width end
function GUI.getPreviousWindowWidth() return previousWidth end
function GUI.getWindowWidthChange() return width - previousWidth end
function GUI.windowWidthJustChanged() return width ~= previousWidth end

function GUI.getWindowHeight() return height end
function GUI.getPreviousWindowHeight() return previousHeight end
function GUI.getWindowHeightChange() return height - previousHeight end
function GUI.windowHeightJustChanged() return height ~= previousHeight end

function GUI.windowWasResized() return (width ~= previousWidth) or (height ~= previousHeight) end

function GUI.setDestination(value) gfx.dest = value end
function GUI.setAlpha(value) gfx.a = value end
function GUI.setColor(color)
    local mode = color[5] or 0
    gfxSet(color[1], color[2], color[3], color[4], mode)
end
function GUI.setBlendMode(mode)
    gfx.mode = mode
end
function GUI.drawRectangle(x, y, w, h, filled)
    gfxRect(x, y, w, h, filled)
end
function GUI.drawLine(x, y, x2, y2, antiAliased)
    gfxLine(x, y, x2, y2, antiAliased)
end
function GUI.drawCircle(x, y, r, filled, antiAliased)
    gfxCircle(x, y, r, filled, antiAliased)
end
function GUI.drawRoundRectangle(x, y, w, h, r, filled, antiAliased)
    local aa = antiAliased or 1
    filled = filled or 0
    w = math.max(0, w - 1)
    h = math.max(0, h - 1)

    if filled == 0 or false then
        gfxRoundRect(x, y, w, h, r, aa)
    else
        if h >= 2 * r then
            -- Corners
            gfxCircle(x + r, y + r, r, 1, aa)		   -- top-left
            gfxCircle(x + w - r, y + r, r, 1, aa)	   -- top-right
            gfxCircle(x + w - r, y + h - r, r , 1, aa) -- bottom-right
            gfxCircle(x + r, y + h - r, r, 1, aa)	   -- bottom-left

            -- Ends
            gfxRect(x, y + r, r, h - r * 2)
            gfxRect(x + w - r, y + r, r + 1, h - r * 2)

            -- Body + sides
            gfxRect(x + r, y, w - r * 2, h + 1)
        else
            r = (h / 2 - 1)

            -- Ends
            gfxCircle(x + r, y + r, r, 1, aa)
            gfxCircle(x + w - r, y + r, r, 1, aa)

            -- Body
            gfxRect(x + r, y, w - (r * 2), h)
        end
    end
end
function GUI.drawString(str, x, y, flags, right, bottom)
    gfx.x = x
    gfx.y = y
    if flags then
        gfxDrawStr(str, flags, right, bottom)
    else
        gfxDrawStr(str)
    end
end
function GUI.setFont(font, size, flags)
    gfxSetFont(1, font, size)
end
function GUI.measureString(str)
    return gfxMeasureStr(str)
end
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

    GUI.onUpdate()
    GUI.onDraw()
    GUI.onEndUpdate()

    if char ~= "Escape" and char ~= "Close" then reaper.defer(GUI.run) end
    gfx.update()

    previousWidth = width
    previousHeight = height
    previousMouseX = mouseX
    previousMouseY = mouseY
end

return GUI