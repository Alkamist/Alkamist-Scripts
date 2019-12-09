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

local MouseButton = {}

function MouseButton:new()
    local self = self or {}
    Button.new(self)
    for k, v in pairs(MouseButton) do self[k] = v end
    return self
end

function MouseButton:getButtonName() return self._buttonName end
function MouseButton:setButtonName(v) self._buttonName = v end

function MouseButton:updateState(dt)
    self:setIsPressed(mouseStateFns[self:getButtonName()]())
    self:setX(GUI.mouseX)
    self:setY(GUI.mouseY)
end

local listOfButtons = {}
local MouseButtons = {}
for k, v in pairs(mouseStateFns) do
    local newButton = MouseButton.new()
    newButton:setButtonName(k)

    MouseButtons[k] = newButton
    listOfButtons[#listOfButtons + 1] = MouseButtons[k]
end

function MouseButtons:updateState(dt)
    for i = 1, #listOfButtons do
        listOfButtons[i]:update(dt)
    end
end

return MouseButtons