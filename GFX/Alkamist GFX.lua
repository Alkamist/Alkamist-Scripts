local Alk = require "API.Alkamist API"

local GFX = {}

GFX.runHook = GFX.runHook or function() end
GFX.children = GFX.children or {}

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
local characterTableInverted = Alk.invertTable(characterTable)
function GFX.getChar(char)
    if char then return gfx.getchar(characterTable[char]) end
    return characterTableInverted[gfx.getchar()]
end

function GFX.setColor(color)
    gfx.set(color[1], color[2], color[3], color[4])
end

function GFX.wasResized()
    return GFX.w ~= GFX.prevW or GFX.h ~= GFX.prevH
end

function GFX.mouseMoved()
    return GFX.mouseX ~= GFX.prevMouseX or GFX.mouseY ~= GFX.prevMouseY
end

local function makeMouseCapState(bitValue)
    return setmetatable({}, {
        __index = function(tbl, key)
            if key == "isPressed" then return GFX.mouseCap & bitValue == bitValue end
            if key == "justPressed" then return (GFX.mouseCap & bitValue == bitValue) and (GFX.prevMouseCap & bitValue == 0) end
            if key == "justReleased" then return (GFX.mouseCap & bitValue == 0) and (GFX.prevMouseCap & bitValue == bitValue) end
            return tbl[key]
        end
    })
end
GFX.mouseButtons = {
    left = makeMouseCapState(1),
    middle = makeMouseCapState(64),
    right = makeMouseCapState(2)
}
GFX.mods = {
    Control = makeMouseCapState(4),
    Shift = makeMouseCapState(8),
    Alt = makeMouseCapState(16),
    Windows = makeMouseCapState(32)
}
GFX.keys = {}
for char, charValue in pairs(characterTable) do
    local wasPressedPreviously = nil
    GFX.keys[char] = {
        __index = function(tbl, key)
            if key == "isPressed" then
                local isPressed = GFX.getChar(char) > 0
                wasPressedPreviously = isPressed
                return isPressed
            end
            if key == "justPressed" then
                local wasPressedPreviously = wasPressedPreviously
                return tbl.isPressed and (not wasPressedPreviously)
            end
            if key == "justReleased" then
                local wasPressedPreviously = wasPressedPreviously
                return (not tbl.isPressed) and wasPressedPreviously
            end
            return tbl[key]
        end
    }
    setmetatable(GFX.keys[char], GFX.keys[char])
end

function GFX.init(title, x, y, w, h, dock)
    gfx.init(title, w, h, dock, x, y)
    GFX.title = title
    GFX.x = x
    GFX.prevX = x
    GFX.y = y
    GFX.prevY = y
    GFX.w = w
    GFX.prevW = w
    GFX.h = h
    GFX.prevH = h
    GFX.dock = 0
end

function GFX.run()
    -- Update current gfx variables.
    GFX.char =        GFX.getChar()
    GFX.x =           gfx.x
    GFX.y =           gfx.y
    GFX.w =           gfx.w
    GFX.h =           gfx.h
    GFX.mouseX =      gfx.mouse_x
    GFX.mouseY =      gfx.mouse_y
    GFX.mouseCap =    gfx.mouse_cap
    GFX.mouseWheel =  math.floor(gfx.mouse_wheel / 120.0); gfx.mouse_wheel = 0
    GFX.mouseHWheel = math.floor(gfx.mouse_hwheel / 120.0); gfx.mouse_hwheel = 0

    -- Initialize previous gfx variables.
    GFX.prevX =           GFX.prevX or GFX.x
    GFX.prevY =           GFX.prevY or GFX.y
    GFX.prevW =           GFX.prevW or GFX.w
    GFX.prevH =           GFX.prevH or GFX.h
    GFX.prevMouseX =      GFX.prevMouseX or GFX.mouseX
    GFX.prevMouseY =      GFX.prevMouseY or GFX.mouseY
    GFX.prevMouseCap =    GFX.prevMouseCap or GFX.mouseCap
    GFX.prevMouseWheel =  GFX.prevMouseWheel or GFX.mouseWheel
    GFX.prevMouseHWheel = GFX.prevMouseHWheel or GFX.mouseHWheel

    -- Allow the play key to play the current project.
    if GFX.playKey and GFX.char == GFX.playKey then reaper.Main_OnCommandEx(40044, 0, 0) end

    -- Run the user defined hook function.
    GFX.runHook()

    -- Go through all of the children and activate their events if needed.
    for _, child in pairs(GFX.children) do
        GFX.focus = GFX.focus or child
        child:onUpdate()
        if GFX.wasResized()                 then child:onResize(GFX.w - GFX.prevW, GFX.h - GFX.prevH) end
        if GFX.focus == child and GFX.char  then child:onChar(GFX.char) end
        if child:mouseJustEntered()         then child:onMouseEnter() end
        if child:mouseJustLeft()            then child:onMouseLeave() end
        if child:mouseIsInside() then
            if GFX.mouseButtons.left.justPressed   then child:onLeftMouseDown() end
            if GFX.mouseButtons.middle.justPressed then child:onMiddleMouseDown() end
            if GFX.mouseButtons.right.justPressed  then child:onRightMouseDown() end
            if GFX.mouseMoved() then
                if GFX.mouseButtons.left.isPressed   then child:onLeftMouseDrag() end
                if GFX.mouseButtons.middle.isPressed then child:onMiddleMouseDrag() end
                if GFX.mouseButtons.right.isPressed  then child:onRightMouseDrag() end
            end
            if GFX.mouseWheel > 0 or GFX.mouseWheel < 0   then child:onMouseWheel(GFX.mouseWheel) end
            if GFX.mouseHWheel > 0 or GFX.mouseHWheel < 0 then child:onMouseHWheel(GFX.mouseHWheel) end
        end
        if GFX.mouseButtons.left.justReleased   then child:onLeftMouseUp() end
        if GFX.mouseButtons.middle.justReleased then child:onMiddleMouseUp() end
        if GFX.mouseButtons.right.justReleased  then child:onRightMouseUp() end
        child:draw()
    end

    -- Keep the loop running.
	if GFX.char ~= "Escape" and GFX.char ~= "Close" then reaper.defer(GFX.run) end
    gfx.update()

    -- Update previous gfx variables.
    GFX.prevX =           GFX.x
    GFX.prevY =           GFX.y
    GFX.prevW =           GFX.w
    GFX.prevH =           GFX.h
    GFX.prevMouseX =      GFX.mouseX
    GFX.prevMouseY =      GFX.mouseY
    GFX.prevMouseCap =    GFX.mouseCap
    GFX.prevMouseWheel =  GFX.mouseWheel
    GFX.prevMouseHWheel = GFX.mouseHWheel
end

return GFX