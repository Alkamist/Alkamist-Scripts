local GUI = require("GUI")
local Button = require("Button")

local mouseStateFns = {
    left = function() return GUI.leftMouseButtonIsPressed end,
    middle = function() return GUI.middleMouseButtonIsPressed end,
    right = function() return GUI.rightMouseButtonIsPressed end,
    shift = function() return GUI.shiftKeyIsPressed end,
    control = function() return GUI.controlKeyIsPressed end,
    windows = function() return GUI.windowsKeyIsPressed end,
    alt = function() return GUI.altKeyIsPressed end,
}



local function MouseButton(self)
    local self = self or {}
    if self.MouseButton then return self end
    self.MouseButton = true
    Button(self)
    local _buttonUpdateState = self.updateState

    local _buttonName

    function self.getButtonName() return _buttonName end
    function self.setButtonName(v) _buttonName = v end

    function self.updateState(dt)
        self.setIsPressed(mouseStateFns[self.getButtonName()]())
        self.setX(GUI.mouseX)
        self.setY(GUI.mouseY)
        _buttonUpdateState(dt)
    end

    return self
end



local listOfButtons = {}
local MouseButtons = {}
for k, v in pairs(mouseStateFns) do
    local newButton = MouseButton()
    newButton.setButtonName(k)

    MouseButtons[k] = newButton
    listOfButtons[#listOfButtons + 1] = MouseButtons[k]
end

function MouseButtons.updateState(dt)
    for i = 1, #listOfButtons do
        listOfButtons[i].updateState(dt)
    end
end
function MouseButtons.updatePreviousState(dt)
    for i = 1, #listOfButtons do
        listOfButtons[i].updatePreviousState(dt)
    end
end

return MouseButtons