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

local GFX = {
    title =            "",
    backgroundColor =  {},
    x =                0,
    y =                0,
    w =                0,
    previousW =        0,
    wChange =          0,
    h =                0,
    previousH =        0,
    hChange =          0,
    dock =             0,
    focus =            nil,
    windowWasResized = false,
    children =         {},
    numberOfChildren = 0,
    mouseX =           0,
    previousMouseX =   0,
    mouseXChange =     0,
    mouseY =           0,
    previousMouseY =   0,
    mouseYChange =     0,
    wheel =            0,
    hWheel =           0,
    mouseCap =         0,
    previousMouseCap = 0,
    char =             0,
    leftState =        false,
    leftDown =         false,
    leftUp =           false,
    middleState =      false,
    middleDown =       false,
    middleUp =         false,
    rightState =       false,
    rightDown =        false,
    rightUp =          false,
    shiftState =       false,
    shiftDown =        false,
    shiftUp =          false,
    controlState =     false,
    controlDown =      false,
    controlUp =        false,
    altState =         false,
    altDown =          false,
    altUp =            false,
    windowsState =     false,
    windowsDown =      false,
    windowsUp =        false,
    mouseMoved =       false
}

function GFX:setBackgroundColor(color)
    self.backgroundColor = color
    gfx.clear = color[1] * 255 + color[2] * 255 * 256 + color[3] * 255 * 65536
end
function GFX:setColor(color)
    gfx.set(color[1], color[2], color[3], color[4])
end
function GFX:drawRectangle(x, y, w, h, filled)
    gfx.rect(x, y, w, h, filled)
end
function GFX:drawLine(x, y, x2, y2, antiAliased)
    gfx.line(x, y, x2, y2, antiAliased)
end
function GFX:drawCircle(x, y, r, filled, antiAliased)
    gfx.circle(x, y, r, filled, antiAliased)
end

function GFX:setChildren(children)
    self.children = children
    for index, child in pairs(self.children) do
        self.numberOfChildren = index
    end
end



function GFX:init(title, x, y, w, h, dock)
    gfx.init(title, w, h, dock, x, y)

    self.title = title
    self.x =     x
    self.y =     y
    self.w =     w
    self.h =     h
    self.dock =  dock
end

function GFX:update()
    local mouseCap = gfx.mouse_cap

    self.previousW =        self.w
    self.previousH =        self.h
    self.previousMouseX =   self.mouseX
    self.previousMouseY =   self.mouseY
    self.previousMouseCap = self.mouseCap

    self.x =                gfx.x
    self.y =                gfx.y
    self.w =                gfx.w
    self.wChange =          self.w - self.previousW
    self.h =                gfx.h
    self.hChange =          self.h - self.previousH
    self.windowWasResized = self.w ~= self.previousW or self.h ~= self.previousH
    self.mouseX =           gfx.mouse_x
    self.mouseXChange =     self.mouseX - self.previousMouseX
    self.mouseY =           gfx.mouse_y
    self.mouseYChange =     self.mouseY - self.previousMouseY
    self.wheel =            gfx.mouse_wheel / 120
    gfx.mouse_wheel =       0
    self.hWheel =           gfx.mouse_hwheel / 120
    gfx.mouse_hwheel =      0
    self.mouseCap =         gfx.mouse_cap
    self.char =             characterTableInverted[gfx.getchar()]
    self.leftState =        self.mouseCap & 1 == 1
    self.leftDown =         self.mouseCap & 1 == 1 and self.previousMouseCap & 1 == 0
    self.leftUp =           self.mouseCap & 1 == 0 and self.previousMouseCap & 1 == 1
    self.middleState =      self.mouseCap & 64 == 64
    self.middleDown =       self.mouseCap & 64 == 64 and self.previousMouseCap & 64 == 0
    self.middleUp =         self.mouseCap & 64 == 0 and self.previousMouseCap & 64 == 64
    self.rightState =       self.mouseCap & 2 == 2
    self.rightDown =        self.mouseCap & 2 == 2 and self.previousMouseCap & 2 == 0
    self.rightUp =          self.mouseCap & 2 == 0 and self.previousMouseCap & 2 == 2
    self.shiftState =       self.mouseCap & 8 == 8
    self.shiftDown =        self.mouseCap & 8 == 8 and self.previousMouseCap & 8 == 0
    self.shiftUp =          self.mouseCap & 8 == 0 and self.previousMouseCap & 8 == 8
    self.controlState =     self.mouseCap & 4 == 4
    self.controlDown =      self.mouseCap & 4 == 4 and self.previousMouseCap & 4 == 0
    self.controlUp =        self.mouseCap & 4 == 0 and self.previousMouseCap & 4 == 4
    self.altState =         self.mouseCap & 16 == 16
    self.altDown =          self.mouseCap & 16 == 16 and self.previousMouseCap & 16 == 0
    self.altUp =            self.mouseCap & 16 == 0 and self.previousMouseCap & 16 == 16
    self.windowsState =     self.mouseCap & 32 == 32
    self.windowsDown =      self.mouseCap & 32 == 32 and self.previousMouseCap & 32 == 0
    self.windowsUp =        self.mouseCap & 32 == 0 and self.previousMouseCap & 32 == 32
    self.mouseMoved =       self.mouseX ~= self.previousMouseX or self.mouseY ~= self.previousMouseY
end
function GFX:processChildren()
    for i = 1, self.numberOfChildren do
        local child = self.children[i]
        self.focus = self.focus or child

        child.previousRelativeMouseX = self.previousMouseX - child.x
        child.previousRelativeMouseY = self.previousMouseY - child.y
        child.relativeMouseX =         self.mouseX - child.x
        child.relativeMouseY =         self.mouseY - child.y
        child.mouseIsInside = child.relativeMouseX >= 0 and child.relativeMouseX <= child.w
                          and child.relativeMouseY >= 0 and child.relativeMouseY <= child.h
        child.mouseWasPreviouslyInside = child.previousRelativeMouseX >= 0 and child.previousRelativeMouseX <= child.w
                                     and child.previousRelativeMouseY >= 0 and child.previousRelativeMouseY <= child.h
        child.mouseJustEntered = child.mouseIsInside and not child.mouseWasPreviouslyInside
        child.mouseJustLeft =    not child.mouseIsInside and child.mouseWasPreviouslyInside

        child:onUpdate()
        if self.windowWasResized             then child:onResize() end
        if self.focus == child and self.char then child:onKeyPress() end
        if child.mouseJustEntered            then child:onMouseEnter() end
        if child.mouseJustLeft               then child:onMouseLeave() end

        if child.mouseIsInside then
            if self.leftDown then
                child.leftDragIsEnabled = true
                child:onMouseLeftButtonDown()
            end
            if self.middleDown then
                child.middleDragIsEnabled = true
                child:onMouseMiddleButtonDown()
            end
            if self.rightDown then
                child.rightDragIsEnabled = true
                child:onMouseRightButtonDown()
            end

            if self.wheel > 0 or self.wheel < 0 then   child:onMouseWheel() end
            if self.hWheel > 0 or self.hWheel < 0 then child:onMouseHWheel() end
        end

        if self.mouseMoved and child.leftDragIsEnabled then
            child.leftIsDragging = true
            child:onMouseLeftButtonDrag()
        end
        if self.mouseMoved and child.middleDragIsEnabled then
            child.middleIsDragging = true
            child:onMouseMiddleButtonDrag()
        end
        if self.mouseMoved and child.rightDragIsEnabled then
            child.rightIsDragging = true
            child:onMouseRightButtonDrag()
        end

        if self.leftUp then
            child:onMouseLeftButtonUp()
            child.leftIsDragging = false
            child.leftDragIsEnabled = false
        end
        if self.middleUp then
            child:onMouseMiddleButtonUp()
            child.middleIsDragging = false
            child.middleDragIsEnabled = false
        end
        if self.rightUp then
            child:onMouseRightButtonUp()
            child.rightIsDragging = false
            child.rightDragIsEnabled = false
        end

        child:onDraw()
    end
end
function GFX.run()
    local self = GFX

    self:update()
    if self.char == "Space" then reaper.Main_OnCommandEx(40044, 0, 0) end
    self:processChildren()
    if self.char ~= "Escape" and self.char ~= "Close" then reaper.defer(self.run) end
    gfx.update()
end

return GFX