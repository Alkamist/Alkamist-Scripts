local pairs = pairs

local Button = require("Button")

local MouseButtons = {}

function MouseButtons.new(GUI)
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
        local button = {}

        function button:update()
            button.isPressed = buttonIsPressedFn()
            button.x = GUI.mouseX
            button.y = GUI.mouseY

            Button.updateMovingButton(button)

            button.wasPreviouslyPressed = button.isPressed
            button.previousX = button.x
            button.previousY = button.y
        end

        buttons[buttonName] = button
    end

    return buttons
end

return MouseButtons