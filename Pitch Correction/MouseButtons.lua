local GUI = require("GUI")

local mouseStateFns = {
    left = function() return GUI.leftMouseButtonIsPressed end,
    middle = function() return GUI.middleMouseButtonIsPressed end,
    right = function() return GUI.rightMouseButtonIsPressed end,
    shift = function() return GUI.shiftKeyIsPressed end,
    control = function() return GUI.controlKeyIsPressed end,
    windows = function() return GUI.windowsKeyIsPressed end,
    alt = function() return GUI.altKeyIsPressed end,
}

local MouseButtons = {}
for k, v in pairs(mouseStateFns) do
    MouseButtons[k] = {}
end

function MouseButtons:updateState(dt)
    for k, v in pairs(mouseStateFns) do
        self[k].isPressed = v()
        self[k].x = GUI.mouseX
        self[k].y = GUI.mouseY
    end
end

return MouseButtons