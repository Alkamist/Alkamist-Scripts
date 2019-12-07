local tiny = require("tiny")
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

local MouseButtons = tiny.processingSystem()

MouseButtons.filter = tiny.requireAll(
    "mouseButtonName"
)

function MouseButtons:onAdd(e)

end

function MouseButtons:process(e, dt)
    e.isPressed = mouseStateFns[e.mouseButtonName]()
    e.x = GUI.mouseX
    e.y = GUI.mouseY
end

return MouseButtons