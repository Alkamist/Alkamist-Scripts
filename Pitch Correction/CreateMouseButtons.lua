local pairs = pairs

local Button = require("Button")
local MovingButton = require("MovingButton")

local function createMouseButtons(GUI)
    local buttons = {}
    local states = {
        left = GUI.leftMouseButtonIsPressed,
        middle = GUI.middleMouseButtonIsPressed,
        right = GUI.rightMouseButtonIsPressed,
        shift = GUI.shiftKeyIsPressed,
        control = GUI.controKeyIsPressed,
        windows = GUI.windowsKeyIsPressed,
        alt = GUI.altKeyIsPressed,
    }

    for buttonName, buttonIsPressedFn in pairs(states) do
        local _wasPreviouslyPressed = false
        local _previousX = 0
        local _previousY = 0

        local button = Button.new{
            isPressed = buttonIsPressedFn,
            getX = GUI.getMouseX,
            getY = GUI.getMouseY,
            wasPreviouslyPressed = function() return _wasPreviouslyPressed end,
            getPreviousX = function() return _previousX end,
            getPreviousY = function() return _previousY end
        }
        button = MovingButton.new(button)

        local _oldUpdate = button.update
        function button:update()
            _oldUpdate(self)
            _wasPreviouslyPressed = self:isPressed()
            _previousX = self:getX()
            _previousY = self:getY()
        end

        buttons[buttonName] = button
    end

    return buttons
end

return createMouseButtons