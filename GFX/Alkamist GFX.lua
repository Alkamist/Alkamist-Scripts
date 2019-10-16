local GFX = {}
GFX.runHook = GFX.runHook or function() end
local function updateVars()
    GFX.char = GFX.getChar()
    GFX.x  = gfx.x
    GFX.y = gfx.y
    GFX.w = gfx.w
    GFX.h = gfx.h
    GFX.mouseX = gfx.mouse_x
    GFX.mouseY = gfx.mouse_y
    GFX.mouseCap = gfx.mouse_cap
    GFX.mouseWheel = gfx.mouse_wheel; gfx.mouse_wheel = 0
    GFX.mouseHWheel = gfx.mouse_hwheel; gfx.mouse_hwheel = 0
end
local function updatePrevVars()
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
    updateVars()
    if GFX.playKey and GFX.char == GFX.playKey then reaper.Main_OnCommandEx(40044, 0, 0) end

    GFX.runHook()

    for _, child in pairs(GFX.children) do
        if GFX.w ~= GFX.prevW or GFX.h ~= GFX.prevH then
            child:onResize()
        end
        child:draw()
    end

	if GFX.char ~= "Escape" and GFX.char ~= "Close" then reaper.defer(GFX.loop) end
    gfx.update()
    updatePrevVars()
end
function GFX.run(title, x, y, w, h, dock)
    GFX.init(title, x, y, w, h, dock)
    GFX.loop()
end

return GFX