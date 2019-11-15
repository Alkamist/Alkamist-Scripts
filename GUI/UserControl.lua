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
local Prototype = require("Prototype")
local Toggle = require("GUI.Toggle")
local TrackedNumber = require("GUI.TrackedNumber")

--==============================================================
--== Mouse =====================================================
--==============================================================

local MouseControl = Prototype:new{
    mouse = {},
    wasPressedInsideWidget = {},
    pressState = Toggle,
    isAlreadyDragging = false,
    wasJustReleasedLastFrame = false,
    timeOfPreviousPress = 0,
    timeSincePreviousPress = {
        get = function(self)
            if not self.timeOfPreviousPress then return nil end
            return reaper.time_precise() - self.timeOfPreviousPress
        end
    },

    isPressed = {
        get = function(self) return self.pressState.currentState end,
        set = function(self, value) self.pressState.currentState = value end,
    },
    justPressed = { get = function(self) return self.pressState.justTurnedOn end },
    justReleased = { get = function(self) return self.pressState.justTurnedOff end },
    justDoublePressed = {
        get = function(self)
            local timeSince = self.timeSincePreviousPress
            if timeSince == nil then return false end
            return self.justPressed and timeSince <= 0.5
        end
    },

    justDragged = false,
    justStartedDragging = { get = function(self) return self.justDragged and not self.isAlreadyDragging end },
    justStoppedDragging = { get = function(self) return self.justReleased and self.isAlreadyDragging end },

    isPressedInWidget = function(self, widget) return self.isPressed and self.mouse:isInsideWidget(widget) end,
    justPressedWidget = function(self, widget) return self.justPressed and self.mouse:isInsideWidget(widget) end,
    justReleasedWidget = function(self, widget) return self.justReleased and self.wasPressedInsideWidget[widget] end,
    justDoublePressedWidget = function(self, widget) return self.justDoublePressed and self.mouse:isInsideWidget(widget) end,
    justDraggedWidget = function(self, widget) return self.justDragged and self.wasPressedInsideWidget[widget] end,
    justStartedDraggingWidget = function(self, widget) return self.justDragged and not self.isAlreadyDragging and self.wasPressedInsideWidget[widget] end,
    justStoppedDraggingWidget = function(self, widget) return self.justReleased and self.isAlreadyDragging and self.wasPressedInsideWidget[widget] end,
    updateWidgetPressState = function(self, widget)
        if self.wasJustReleasedLastFrame then self.wasPressedInsideWidget[widget] = false end
        if self:justPressedWidget(widget) then self.wasPressedInsideWidget[widget] = true end
        local childWidgets = widget.widgets
        if childWidgets then
            for i = 1, #childWidgets do
                self:updateWidgetPressState(childWidgets[i])
            end
        end
    end,
    update = function(self, state)
        if self.justPressed then self.timeOfPreviousPress = reaper.time_precise() end
        if self.justReleased then self.isAlreadyDragging = false end

        self.wasJustReleasedLastFrame = self.justReleased
        self.pressState:update(state)

        local widgets = self.mouse.widgets
        if widgets then
            for i = 1, #widgets do self:updateWidgetPressState(widgets[i]) end
        end

        if self.justDragged then self.isAlreadyDragging = true end
        self.justDragged = self.isPressed and self.mouse.justMoved
    end
}

local MouseButton = Prototype:new{
    prototypes = { { "mouseControl", MouseControl } },
    bitValue = 0,
    update = function(self)
        self.mouseControl:update(self.mouse.cap & self.bitValue == self.bitValue)
    end
}

local Mouse = Prototype:new{
    calledWhenCreated = function(self)
        self.leftButton.mouse = self
        self.middleButton.mouse = self
        self.rightButton.mouse = self
    end,

    cap = 0,
    wheel = 0,
    hWheel = 0,
    widgets = {},

    xTracker = TrackedNumber,
    x = {
        get = function(self) return self.xTracker.currentValue end,
        set = function(self, value) self.xTracker.currentValue = value end,
    },
    previousX = { get = function(self) return self.xTracker.previousValue end },
    xJustChanged = { get = function(self) return self.xTracker.justChanged end },
    xChange = { get = function(self) return self.xTracker.change end },

    yTracker = TrackedNumber,
    y = {
        get = function(self) return self.yTracker.currentValue end,
        set = function(self, value) self.yTracker.currentValue = value end,
    },
    previousY = { get = function(self) return self.yTracker.previousValue end },
    yJustChanged = { get = function(self) return self.yTracker.justChanged end },
    yChange = { get = function(self) return self.yTracker.change end },

    leftButton = MouseButton:withDefaults{ bitValue = 1 },
    middleButton = MouseButton:withDefaults{ bitValue = 64 },
    rightButton = MouseButton:withDefaults{ bitValue = 2 },

    justMoved = { get = function(self) return self.xJustChanged or self.yJustChanged end },
    wheelJustMoved = { get = function(self) return self.wheel ~= 0 end },
    hWheelJustMoved = { get = function(self) return self.hWheel ~= 0 end },
    wasPreviouslyInsideWidget = function(self, widget) return widget:pointIsInside(self.previousX, self.previousY) end,
    isInsideWidget = function(self, widget) return widget:pointIsInside(self.x, self.y) end,
    justEnteredWidget = function(self, widget) return self:isInsideWidget(widget) and not self:wasPreviouslyInsideWidget(widget) end,
    justLeftWidget = function(self, widget) return not self:isInsideWidget(widget) and self:wasPreviouslyInsideWidget(widget) end,
    update = function(self)
        self.xTracker:update(gfx.mouse_x)
        self.yTracker:update(gfx.mouse_y)
        self.cap = gfx.mouse_cap
        self.wheel = gfx.mouse_wheel / 120
        gfx.mouse_wheel = 0
        self.hWheel = gfx.mouse_hwheel / 120
        gfx.mouse_hwheel = 0
        self.leftButton:update()
        self.middleButton:update()
        self.rightButton:update()
    end
}

--==============================================================
--== Keyboard ==================================================
--==============================================================

local KeyboardKey = Prototype:new{
    prototypes = { { "mouseControl", MouseControl } },
    character = "",
    update = function(self) self.mouseControl:update(gfx.getchar(characterTable[self.character]) > 0) end
}

local Keyboard = Prototype:new{
    mouse = {
        value = {},
        get = function(self, field) return field.value end,
        set = function(self, value, field)
            self.shiftKey.mouse = value
            self.controlKey.mouse = value
            self.windowsKey.mouse = value
            self.altKey.mouse = value
            field.value = value
        end
    },
    currentCharacter = nil,
    shiftKey = MouseButton:withDefaults{ bitValue = 8 },
    controlKey = MouseButton:withDefaults{ bitValue = 4 },
    windowsKey = MouseButton:withDefaults{ bitValue = 32 },
    altKey = MouseButton:withDefaults{ bitValue = 16 },
    keys = {},
    createKey = function(self, character)
        self.keys[character] = KeyboardKey:new{ mouse = self.mouse, character = character }
    end,
    update = function(self)
        self.shiftKey:update()
        self.controlKey:update()
        self.windowsKey:update()
        self.altKey:update()
        for name, key in pairs(self.keys) do key:update() end
        self.currentCharacter = characterTableInverted[gfx.getchar()]
    end
}

local UserControl = { mouse = Mouse:new() }
UserControl.keyboard = Keyboard:new{ mouse = UserControl.mouse }
return UserControl