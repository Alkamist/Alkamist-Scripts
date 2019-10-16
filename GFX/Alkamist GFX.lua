local GFX = {}
GFX.runHook = GFX.runHook or function() end
local function invertTable(tbl)
    local s = {}
    for key, value in pairs(tbl) do
      s[value] = key
    end
    return s
end
local characterTable = {
    ["Close"] = -1,
    ["Enter"] = 13,
    ["Escape"] = 27,
    ["Space"] = 32,
    ["!"] = 33,
    ["\""] = 34,
    ["#"] = 35,
    ["$"] = 36,
    ["%"] = 37,
    ["&"] = 38,
    ["\'"] = 39,
    ["("] = 40,
    [")"] = 41,
    ["*"] = 42,
    ["+"] = 43,
    [","] = 44,
    ["."] = 45,
    ["/"] = 47,
    ["0"] = 48,
    ["1"] = 49,
    ["2"] = 50,
    ["3"] = 51,
    ["4"] = 52,
    ["5"] = 53,
    ["6"] = 54,
    ["7"] = 55,
    ["8"] = 56,
    ["9"] = 57,
    [":"] = 58,
    [";"] = 59,
    ["<"] = 60,
    ["="] = 61,
    [">"] = 62,
    ["?"] = 63,
    ["@"] = 64,
    ["A"] = 65,
    ["B"] = 66,
    ["C"] = 67,
    ["D"] = 68,
    ["E"] = 69,
    ["F"] = 70,
    ["G"] = 71,
    ["H"] = 72,
    ["I"] = 73,
    ["J"] = 74,
    ["K"] = 75,
    ["L"] = 76,
    ["M"] = 77,
    ["N"] = 78,
    ["O"] = 79,
    ["P"] = 80,
    ["Q"] = 81,
    ["R"] = 82,
    ["S"] = 83,
    ["T"] = 84,
    ["U"] = 85,
    ["V"] = 86,
    ["W"] = 87,
    ["X"] = 88,
    ["Y"] = 89,
    ["Z"] = 90,
    ["%["] = 91,
    ["\\"] = 92,
    ["%]"] = 93,
    ["^"] = 94,
    ["_"] = 95,
    ["`"] = 96,
    ["a"] = 97,
    ["b"] = 98,
    ["c"] = 99,
    ["d"] = 100,
    ["e"] = 101,
    ["f"] = 102,
    ["g"] = 103,
    ["h"] = 104,
    ["i"] = 105,
    ["j"] = 106,
    ["k"] = 107,
    ["l"] = 108,
    ["m"] = 109,
    ["n"] = 110,
    ["o"] = 111,
    ["p"] = 112,
    ["q"] = 113,
    ["r"] = 114,
    ["s"] = 115,
    ["t"] = 116,
    ["u"] = 117,
    ["v"] = 118,
    ["w"] = 119,
    ["x"] = 120,
    ["y"] = 121,
    ["z"] = 122,
    ["{"] = 123,
    ["|"] = 124,
    ["}"] = 125,
    ["~"] = 126,
    ["Delete"] = 127
}
local characterTableInverted = invertTable(characterTable)
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

function GFX.pointIsInsideChild(point, child)
    return point.x >= child.x and point.x <= child.x + child.w
       and point.y >= child.Y and point.y <= child.y + child.h
end
function GFX.mouseJustEnteredChild(child)
    return GFX.pointIsInsideChild({ GFX.mouseX, GFX.mouseY }, child)
       and ( not GFX.pointIsInsideChild({ GFX.prevMouseX, GFX.prevMouseY }, child) )
end
function GFX.mouseJustLeftChild(child)
    return ( not GFX.pointIsInsideChild({ GFX.mouseX, GFX.mouseY }, child) )
       and GFX.pointIsInsideChild({ GFX.prevMouseX, GFX.prevMouseY }, child)
end

local function makeMouseCapState(bitValue)
    return setmetatable({}, {
        __index = function(tbl, key)
            if key == "isPressed" then return GFX.mouseCap & bitValue == bitValue end
            if key == "wasJustPressed" then return (GFX.mouseCap & bitValue == bitValue) and (GFX.prevMouseCap & bitValue == 0) end
            if key == "wasJustReleased" then return (GFX.mouseCap & bitValue == 0) and (GFX.prevMouseCap & bitValue == bitValue) end
            return tbl[key]
        end
    })
end
GFX.leftMouseButton = makeMouseCapState(1)
GFX.middleMouseButton = makeMouseCapState(64)
GFX.rightMouseButton = makeMouseCapState(2)
GFX.controlKey = makeMouseCapState(4)
GFX.shiftKey = makeMouseCapState(8)
GFX.altKey = makeMouseCapState(16)
GFX.windowsKey = makeMouseCapState(32)

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
function GFX.loop()
    -- Update current gfx variables.
    GFX.char = GFX.getChar()
    GFX.x = gfx.x
    GFX.y = gfx.y
    GFX.w = gfx.w
    GFX.h = gfx.h
    GFX.mouseX = gfx.mouse_x
    GFX.mouseY = gfx.mouse_y
    GFX.mouseCap = gfx.mouse_cap
    GFX.mouseWheel = gfx.mouse_wheel; gfx.mouse_wheel = 0
    GFX.mouseHWheel = gfx.mouse_hwheel; gfx.mouse_hwheel = 0

    -- Initialize previous gfx variables.
    GFX.prevX = GFX.prevX or GFX.x
    GFX.prevY = GFX.prevY or GFX.y
    GFX.prevW = GFX.prevW or GFX.w
    GFX.prevH = GFX.prevH or GFX.h
    GFX.prevMouseX = GFX.prevMouseX or GFX.mouseX
    GFX.prevMouseY = GFX.prevMouseY or GFX.mouseY
    GFX.prevMouseCap = GFX.prevMouseCap or GFX.mouseCap
    GFX.prevMouseWheel = GFX.prevMouseWheel or GFX.mouseWheel
    GFX.prevMouseHWheel = GFX.prevMouseHWheel or GFX.mouseHWheel

    -- Allow the play key to play the current project.
    if GFX.playKey and GFX.char == GFX.playKey then reaper.Main_OnCommandEx(40044, 0, 0) end

    GFX.runHook()

    for _, child in pairs(GFX.children) do
        if GFX.wasResized() then child:onResize() end
        --if GFX.mouseJustEnteredChild(child) then child:onMouseEnter() end
        --if GFX.mouseJustLeftChild(child) then child:onMouseLeave() end
        child:draw()
    end

	if GFX.char ~= "Escape" and GFX.char ~= "Close" then reaper.defer(GFX.loop) end
    gfx.update()

    -- Update previous gfx variables.
    GFX.prevX = GFX.x
    GFX.prevY = GFX.y
    GFX.prevW = GFX.w
    GFX.prevH = GFX.h
    GFX.prevMouseX = GFX.mouseX
    GFX.prevMouseY = GFX.mouseY
    GFX.prevMouseCap = GFX.mouseCap
    GFX.prevMouseWheel = GFX.mouseWheel
    GFX.prevMouseHWheel = GFX.mouseHWheel
end
function GFX.run(title, x, y, w, h, dock)
    GFX.init(title, x, y, w, h, dock)
    GFX.loop()
end

return GFX