local GUI = require("GUI")
local MovingButton = require("MovingButton")

local MouseButtons = {}

local states = {
    left = function() return GUI.leftMouseButtonIsPressed end,
    middle = function() return GUI.middleMouseButtonIsPressed end,
    right = function() return GUI.rightMouseButtonIsPressed end,
    shift = function() return GUI.shiftKeyIsPressed end,
    control = function() return GUI.controlKeyIsPressed end,
    windows = function() return GUI.windowsKeyIsPressed end,
    alt = function() return GUI.altKeyIsPressed end,
}

for buttonName, buttonIsPressedFn in pairs(states) do
    local button = MovingButton:new()

    function button:update()
        self.isPressed = buttonIsPressedFn()
        self.x = GUI.mouseX
        self.y = GUI.mouseY

        MovingButton.update(self)

        self.wasPreviouslyPressed = self.isPressed
        self.previousX = self.x
        self.previousY = self.y
    end

    MouseButtons[buttonName] = button
end

return MouseButtons