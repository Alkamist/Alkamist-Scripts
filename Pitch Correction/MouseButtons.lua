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

function MouseButtons:create(world)
    local buttons = {}
    for k, v in pairs(mouseStateFns) do
        local button = {
            mouseButtonName = k,
            isPressed = false,
            wasPreviouslyPressed = false,
            justPressed = false,
            justReleased = false,
            justMoved = false,
            x = 0,
            y = 0,
            previousX = 0,
            previousY = 0
        }
        world:addEntity(button)
        buttons[k] = button
    end
    return buttons
end

function MouseButtons:process(e, dt)
    e.isPressed = mouseStateFns[e.mouseButtonName]()
    e.x = GUI.mouseX
    e.y = GUI.mouseY
end

return MouseButtons