local pairs = pairs

local Button = require("Button")
local MovingButton = require("MovingButton")

return function(GUI)
    local buttons = {}
    local states = {
        left = function() return GUI.leftMouseButtonIsPressed end,
        middle = function() return GUI.middleMouseButtonIsPressed end,
        right = function() return GUI.rightMouseButtonIsPressed end,
        shift = function() return GUI.shiftKeyIsPressed end,
        control = function() return GUI.controKeyIsPressed end,
        windows = function() return GUI.windowsKeyIsPressed end,
        alt = function() return GUI.altKeyIsPressed end,
    }

    for buttonName, buttonIsPressedFn in pairs(states) do
        local buttonState = {}
        local movingButtonState = {}

        local button = Button({}, buttonState)
        button = MovingButton(button, movingButtonState)

        function button.updateState()
            buttonState.isPressed = buttonIsPressedFn()
            movingButtonState.x = GUI.mouseX
            movingButtonState.y = GUI.mouseY
        end

        buttons[buttonName] = button
    end

    return buttons
end