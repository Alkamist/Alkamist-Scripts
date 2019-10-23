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
    mouseLeftState =   false,
    mouseLeftDown =    false,
    mouseLeftUp =      false,
    mouseMiddleState = false,
    mouseMiddleDown =  false,
    mouseMiddleUp =    false,
    mouseRightState =  false,
    mouseRightDown =   false,
    mouseRightUp =     false,
    mouseMoved =       false,
    shiftKeyState =    false,
    shiftKeyDown =     false,
    shiftKeyUp =       false,
    controlKeyState =  false,
    controlKeyDown =   false,
    controlKeyUp =     false,
    altKeyState =      false,
    altKeyDown =       false,
    altKeyUp =         false,
    windowsKeyState =  false,
    windowsKeyDown =   false,
    windowsKeyUp =     false,
}

function GFX:setBackgroundColor(color)
    self.backgroundColor = color
    gfx.clear = color[1] * 255 + color[2] * 255 * 256 + color[3] * 255 * 65536
end

local currentBuffer = -1
local function getDrawBuffer()
    currentBuffer = currentBuffer + 1
    if currentBuffer > 1023 then currentBuffer = 0 end
    return currentBuffer
end

function GFX:applyFunctionToElements(elements, fn)
    local numberOfElements = #elements
    for i = 1, numberOfElements do
        local element = elements[i]
        fn(element)
    end
end
function GFX:setElements(elements)
    self.elements = elements

    GFX:applyFunctionToElements(self.elements, function(element)
        GFX:initElement(element, nil)
    end)
end
function GFX:initElement(element, parent)
    element.GFX =                      GFX
    element.parent =                   parent
    element.x =                        element.x or 0
    element.y =                        element.y or 0
    element.w =                        element.w or 0
    element.h =                        element.h or 0
    element.drawBuffer =               getDrawBuffer()
    element.previousRelativeMouseX =   0
    element.previousRelativeMouseY =   0
    element.relativeMouseX =           0
    element.relativeMouseY =           0
    element.mouseIsInside =            false
    element.mouseWasPreviouslyInside = false
    element.mouseJustEntered =         false
    element.mouseJustLeft =            false
    element.mouseLeftState =           false
    element.mouseMiddleState =         false
    element.mouseRightState =          false
    element.leftIsDragging =           false
    element.middleIsDragging =         false
    element.rightIsDragging =          false
    element.shouldRedraw =             true
    element.shouldClearBuffer =        false
    element.isVisible =                true

    function element:pointRelativeToParentIsInside(x, y)
        return x >= self.x and x <= self.x + self.w
           and y >= self.y and y <= self.y + self.h
    end
    function element:setColor(color)
        local mode = color[5] or 0
        gfx.set(color[1], color[2], color[3], color[4], mode)
    end
    function element:setBlendMode(mode)
        gfx.mode = mode
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
    function element:drawPolygon(filled, ...)
        if filled then
            gfx.triangle(...)
        else
            local coords = {...}

            -- Duplicate the first pair at the end, so the last line will
            -- be drawn back to the starting point.
            table.insert(coords, coords[1])
            table.insert(coords, coords[2])

            -- Draw a line from each pair of coords to the next pair.
            for i = 1, #coords - 2, 2 do
                gfx.line(coords[i], coords[i+1], coords[i+2], coords[i+3])
            end
        end
    end
    function element:drawRoundRectangle(x, y, w, h, r, filled, antiAliased)
        local aa = antiAliased or 1
        filled = filled or 0
        w = math.max(0, w - 1)
        h = math.max(0, h - 1)

        if filled == 0 or false then
            gfx.roundrect(x, y, w, h, r, aa)
        else
            if h >= 2 * r then
                -- Corners
                gfx.circle(x + r, y + r, r, 1, aa)			-- top-left
                gfx.circle(x + w - r, y + r, r, 1, aa)		-- top-right
                gfx.circle(x + w - r, y + h - r, r , 1, aa) -- bottom-right
                gfx.circle(x + r, y + h - r, r, 1, aa)		-- bottom-left

                -- Ends
                gfx.rect(x, y + r, r, h - r * 2)
                gfx.rect(x + w - r, y + r, r + 1, h - r * 2)

                -- Body + sides
                gfx.rect(x + r, y, w - r * 2, h + 1)
            else
                r = (h / 2 - 1)

                -- Ends
                gfx.circle(x + r, y + r, r, 1, aa)
                gfx.circle(x + w - r, y + r, r, 1, aa)

                -- Body
                gfx.rect(x + r, y, w - (r * 2), h)
            end
        end
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
    function element:setVisibility(visibility)
        self.isVisible = visibility
    end
    function element:hide()
        self:setVisibility(false)
    end
    function element:show()
        self:setVisibility(true)
    end

    if element.onInit then element:onInit() end

    if element.elements then
        GFX:applyFunctionToElements(element.elements, function(elementOfElement)
            GFX:initElement(elementOfElement, element)
        end)
    end
end
function GFX:processElement(element)
    self.focus = self.focus or element

    local parentXOffset = 0
    local parentYOffset = 0
    if element.parent then
        parentXOffset = element.parent.x
        parentYOffset = element.parent.y
    end

    -- Key Press.
    element.keyWasPressed =            element.isVisible and self.char and self.focus == element

    -- Mouse Movement.
    element.previousRelativeMouseX =   self.previousMouseX - element.x - parentXOffset
    element.previousRelativeMouseY =   self.previousMouseY - element.y - parentYOffset
    element.relativeMouseX =           self.mouseX - element.x - parentXOffset
    element.relativeMouseY =           self.mouseY - element.y - parentYOffset
    element.mouseIsInside =            element.isVisible and element.relativeMouseX >= 0 and element.relativeMouseX <= element.w
                                       and element.relativeMouseY >= 0 and element.relativeMouseY <= element.h
    element.mouseWasPreviouslyInside = element.isVisible and element.previousRelativeMouseX >= 0 and element.previousRelativeMouseX <= element.w
                                       and element.previousRelativeMouseY >= 0 and element.previousRelativeMouseY <= element.h
    element.mouseJustEntered =         element.mouseIsInside and not element.mouseWasPreviouslyInside
    element.mouseJustLeft =            not element.mouseIsInside and element.mouseWasPreviouslyInside

    -- Mouse Wheel.
    element.wheelMoved =               element.mouseIsInside and (self.wheel > 0 or self.wheel < 0)
    element.hWheelMoved =              element.mouseIsInside and (self.hWheel > 0 or self.hWheel < 0)

    -- Mouse Down.
    element.mouseLeftDown =            element.mouseIsInside and self.mouseLeftDown
    element.mouseMiddleDown =          element.mouseIsInside and self.mouseMiddleDown
    element.mouseRightDown =           element.mouseIsInside and self.mouseRightDown
    if element.mouseLeftDown   then    element.mouseLeftState = true end
    if element.mouseMiddleDown then    element.mouseMiddleState = true end
    if element.mouseRightDown  then    element.mouseRightState = true end

    -- Mouse Drag.
    element.mouseLeftIsDragging =      self.mouseMoved and element.mouseLeftState
    element.mouseMiddleIsDragging =    self.mouseMoved and element.mouseMiddleState
    element.mouseRightIsDragging =     self.mouseMoved and element.mouseRightState
    if element.mouseLeftIsDragging     then element.mouseLeftWasDragged = true end
    if element.mouseMiddleIsDragging   then element.mouseMiddleWasDragged = true end
    if element.mouseRightIsDragging    then element.mouseRightWasDragged = true end

    -- Mouse Up.
    element.mouseLeftUp =              element.mouseLeftState and self.mouseLeftUp
    element.mouseMiddleUp =            element.mouseMiddleState and self.mouseMiddleUp
    element.mouseRightUp =             element.mouseRightState and self.mouseRightUp
    if element.mouseLeftUp   then      element.mouseLeftState = false end
    if element.mouseMiddleUp then      element.mouseMiddleState = false end
    if element.mouseRightUp  then      element.mouseRightState = false end

    -- Element-Based Events.
    if element.onUpdate                                              then element:onUpdate()          end
    if self.windowWasResized           and element.onWindowResize    then element:onWindowResize()    end
    if element.keyWasPressed           and element.onKeyPress        then element:onKeyPress()        end
    if element.mouseJustEntered        and element.onMouseEnter      then element:onMouseEnter()      end
    if element.mouseJustLeft           and element.onMouseLeave      then element:onMouseLeave()      end
    if element.mouseLeftDown           and element.onMouseLeftDown   then element:onMouseLeftDown()   end
    if element.mouseLeftIsDragging     and element.onMouseLeftDrag   then element:onMouseLeftDrag()   end
    if element.mouseLeftUp             and element.onMouseLeftUp     then element:onMouseLeftUp()     end
    if element.mouseMiddleDown         and element.onMouseMiddleDown then element:onMouseMiddleDown() end
    if element.mouseMiddleIsDragging   and element.onMouseMiddleDrag then element:onMouseMiddleDrag() end
    if element.mouseMiddleUp           and element.onMouseMiddleUp   then element:onMouseMiddleUp()   end
    if element.mouseRightDown          and element.onMouseRightDown  then element:onMouseRightDown()  end
    if element.mouseRightIsDragging    and element.onMouseRightDrag  then element:onMouseRightDrag()  end
    if element.mouseRightUp            and element.onMouseRightUp    then element:onMouseRightUp()    end
    if element.wheelMoved              and element.onMouseWheel      then element:onMouseWheel()      end
    if element.hWheelMoved             and element.onMouseHWheel     then element:onMouseHWheel()     end

    -- Some extra mouse state handling.
    if element.mouseLeftUp   then      element.mouseLeftWasDragged = false end
    if element.mouseMiddleUp then      element.mouseMiddleWasDragged = false end
    if element.mouseRightUp  then      element.mouseRightWasDragged = false end

    -- Handle elements that are queued to draw.
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

    -- Recursively handle any child elements the elements may have.
    if element.elements then
        GFX:applyFunctionToElements(element.elements, function(elementOfElement)
            GFX:processElement(elementOfElement)
        end)
    end
end
function GFX:renderElement(element)
    if element.elements then
        GFX:applyFunctionToElements(element.elements, function(elementOfElement)
            GFX:renderElement(elementOfElement)
        end)
    end

    if element.isVisible then
        if element.parent then
            gfx.dest = element.parent.drawBuffer
        else
            gfx.dest = -1
        end

        --gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs])
        gfx.blit(element.drawBuffer, 1.0, 0, 0, 0, element.w, element.h, element.x, element.y, element.w, element.h, 0, 0)
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
function GFX:updateStates()
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
    self.mouseLeftState =   self.mouseCap & 1 == 1
    self.mouseLeftDown =    self.mouseCap & 1 == 1 and self.previousMouseCap & 1 == 0
    self.mouseLeftUp =      self.mouseCap & 1 == 0 and self.previousMouseCap & 1 == 1
    self.mouseMiddleState = self.mouseCap & 64 == 64
    self.mouseMiddleDown =  self.mouseCap & 64 == 64 and self.previousMouseCap & 64 == 0
    self.mouseMiddleUp =    self.mouseCap & 64 == 0 and self.previousMouseCap & 64 == 64
    self.mouseRightState =  self.mouseCap & 2 == 2
    self.mouseRightDown =   self.mouseCap & 2 == 2 and self.previousMouseCap & 2 == 0
    self.mouseRightUp =     self.mouseCap & 2 == 0 and self.previousMouseCap & 2 == 2
    self.shiftKeyState =    self.mouseCap & 8 == 8
    self.shiftKeyDown =     self.mouseCap & 8 == 8 and self.previousMouseCap & 8 == 0
    self.shiftKeyUp =       self.mouseCap & 8 == 0 and self.previousMouseCap & 8 == 8
    self.controlKeyState =  self.mouseCap & 4 == 4
    self.controlKeyDown =   self.mouseCap & 4 == 4 and self.previousMouseCap & 4 == 0
    self.controlKeyUp =     self.mouseCap & 4 == 0 and self.previousMouseCap & 4 == 4
    self.altKeyState =      self.mouseCap & 16 == 16
    self.altKeyDown =       self.mouseCap & 16 == 16 and self.previousMouseCap & 16 == 0
    self.altKeyUp =         self.mouseCap & 16 == 0 and self.previousMouseCap & 16 == 16
    self.windowsKeyState =  self.mouseCap & 32 == 32
    self.windowsKeyDown =   self.mouseCap & 32 == 32 and self.previousMouseCap & 32 == 0
    self.windowsKeyUp =     self.mouseCap & 32 == 0 and self.previousMouseCap & 32 == 32
    self.mouseMoved =       self.mouseX ~= self.previousMouseX or self.mouseY ~= self.previousMouseY
end
function GFX.run()
    local self = GFX

    self:updateStates()

    if self.char == "Space" then reaper.Main_OnCommandEx(40044, 0, 0) end

    GFX:applyFunctionToElements(self.elements, function(element)
        gfx.a = 1.0
        gfx.mode = 0
        GFX:processElement(element)
    end)

    GFX:applyFunctionToElements(self.elements, function(element)
        gfx.dest = -1
        gfx.a = 1.0
        gfx.mode = 0
        GFX:renderElement(element)
    end)

    if self.char ~= "Escape" and self.char ~= "Close" then reaper.defer(self.run) end
    gfx.update()
end

return GFX