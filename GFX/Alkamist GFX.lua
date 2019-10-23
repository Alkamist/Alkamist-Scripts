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
    elements =         {},
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
function GFX:setElements(elements)
    self.elements = elements
    for _, element in pairs(self.elements) do
        GFX:initElement(element, self)
    end
end

local currentBuffer = -1
local function getDrawBuffer()
    currentBuffer = currentBuffer + 1
    if currentBuffer > 1023 then currentBuffer = 0 end
    return currentBuffer
end
function GFX:initElement(element, parent)
    element.GFX =                      self
    element.parent =                   parent
    element.x =                        element.x or 0
    element.y =                        element.y or 0
    element.w =                        element.w or 0
    element.h =                        element.h or 0
    element.layer =                    element.layer or 0
    element.drawBuffer =               getDrawBuffer()
    element.previousRelativeMouseX =   0
    element.previousRelativeMouseY =   0
    element.relativeMouseX =           0
    element.relativeMouseY =           0
    element.mouseIsInside =            false
    element.mouseWasPreviouslyInside = false
    element.mouseJustEntered =         false
    element.mouseJustLeft =            false
    element.leftWentDownInside =        false
    element.middleWentDownInside =      false
    element.rightWentDownInside =       false
    element.leftIsDragging =           false
    element.middleIsDragging =         false
    element.rightIsDragging =          false
    element.shouldRedraw =             true
    element.shouldClearBuffer =        false

    function element:pointIsInside(x, y)
        return x >= self.x and x <= self.x + self.w
           and y >= self.y and y <= self.y + self.h
    end
    function element:setColor(color)
        gfx.set(color[1], color[2], color[3], color[4])
    end
    function element:drawRectangle(x, y, w, h, filled)
        gfx.rect(x, y, w, h, filled)
    end
    function element:drawLine(x, y, x2, y2, antiAliased)
        gfx.line(x, y, x2, y2, antiAliased)
    end
    function element:drawCircle(x, y, r, filled, antiAliased)
        gfx.circle(x, y, r, filled, antiAliased)
    end
    function element:clearBuffer()
        gfx.setimgdim(self.drawBuffer, -1, -1)
        gfx.setimgdim(self.drawBuffer, self.w, self.h)
    end
    function element:queueRedraw()
        if not self.shouldRedraw then
            self.shouldRedraw = true
        end
    end
    function element:queueClear()
        if self.shouldRedraw then
            self.shouldRedraw = false
        end
        self.shouldClearBuffer = true
    end

    if element.onInit then element:onInit() end

    if element.elements then
        for key, elementOfElement in pairs(element.elements) do
            self:initElement(elementOfElement, element)
        end
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
function GFX:processElement(element)
    self.focus = self.focus or element

    element.previousRelativeMouseX = self.previousMouseX - element.x
    element.previousRelativeMouseY = self.previousMouseY - element.y
    element.relativeMouseX =         self.mouseX - element.x
    element.relativeMouseY =         self.mouseY - element.y
    element.mouseIsInside = element.relativeMouseX >= 0 and element.relativeMouseX <= element.w
                        and element.relativeMouseY >= 0 and element.relativeMouseY <= element.h
    element.mouseWasPreviouslyInside = element.previousRelativeMouseX >= 0 and element.previousRelativeMouseX <= element.w
                                    and element.previousRelativeMouseY >= 0 and element.previousRelativeMouseY <= element.h
    element.mouseJustEntered = element.mouseIsInside and not element.mouseWasPreviouslyInside
    element.mouseJustLeft =    not element.mouseIsInside and element.mouseWasPreviouslyInside

    if element.onUpdate                                             then element:onUpdate() end
    if element.onResize     and self.windowWasResized               then element:onResize() end
    if element.onKeyPress   and self.char and self.focus == element then element:onKeyPress() end
    if element.onMouseEnter and element.mouseJustEntered            then element:onMouseEnter() end
    if element.onMouseLeave and element.mouseJustLeft               then element:onMouseLeave() end

    if element.mouseIsInside then
        if self.leftDown then
            element.leftWentDownInside = true
            if element.onMouseLeftButtonDown then element:onMouseLeftButtonDown() end
        end
        if self.middleDown then
            element.middleWentDownInside = true
            if element.onMouseMiddleButtonDown then element:onMouseMiddleButtonDown() end
        end
        if self.rightDown then
            element.rightWentDownInside = true
            if element.onMouseRightButtonDown then element:onMouseRightButtonDown() end
        end

        if element.onMouseWheel  and (self.wheel > 0 or self.wheel < 0)   then element:onMouseWheel() end
        if element.onMouseHWheel and (self.hWheel > 0 or self.hWheel < 0) then element:onMouseHWheel() end
    end

    if self.mouseMoved and element.leftWentDownInside then
        element.leftIsDragging = true
        if element.onMouseLeftButtonDrag then element:onMouseLeftButtonDrag() end
    end
    if self.mouseMoved and element.middleWentDownInside then
        element.middleIsDragging = true
        if element.onMouseMiddleButtonDrag then element:onMouseMiddleButtonDrag() end
    end
    if self.mouseMoved and element.rightWentDownInside then
        element.rightIsDragging = true
        if element.onMouseRightButtonDrag then element:onMouseRightButtonDrag() end
    end

    if self.leftUp and element.leftWentDownInside then
        if element.onMouseLeftButtonUp then element:onMouseLeftButtonUp() end
        element.leftIsDragging = false
        element.leftWentDownInside = false
    end
    if self.middleUp and element.middleWentDownInside then
        if element.onMouseMiddleButtonUp then element:onMouseMiddleButtonUp() end
        element.middleIsDragging = false
        element.middleWentDownInside = false
    end
    if self.rightUp and element.rightWentDownInside then
        if element.onMouseRightButtonUp then element:onMouseRightButtonUp() end
        element.rightIsDragging = false
        element.rightWentDownInside = false
    end

    if element.onDraw then
        if element.shouldRedraw then
            element:clearBuffer()
            gfx.dest = element.drawBuffer
            element:onDraw()
            element.shouldRedraw = false
        elseif element.shouldClearBuffer then
            element:clearBuffer()
            element.shouldClearBuffer = false
        end
    end

    if element.elements then
        for key, elementOfelement in pairs(element.elements) do
            self:processElement(elementOfelement)
        end
    end
end
function GFX:renderElement(element)
    local xOffset = 0
    local yOffset = 0
    if element.parent then
        xOffset = element.parent.x
        yOffset = element.parent.y
    end

    --gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs])
    gfx.blit(element.drawBuffer, 1.0, 0, 0, 0, element.w, element.h, xOffset + element.x, yOffset + element.y, element.w, element.h, 0, 0)
    if element.elements then
        for key, elementOfElement in pairs(element.elements) do
            self:renderElement(elementOfElement)
        end
    end
end
function GFX.run()
    local self = GFX

    self:update()

    if self.char == "Space" then reaper.Main_OnCommandEx(40044, 0, 0) end

    for key, element in pairs(self.elements) do
        self:processElement(element)
    end
    gfx.dest = -1
    gfx.a = 1.0
    for key, element in pairs(self.elements) do
        self:renderElement(element)
    end

    if self.char ~= "Escape" and self.char ~= "Close" then reaper.defer(self.run) end
    gfx.update()
end

return GFX