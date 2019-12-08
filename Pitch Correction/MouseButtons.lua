local ECS = require("ECS")
local GUI = require("GUI")
local Position = require("Position")
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

function MouseButton:filter()
    return self.MouseButton and self.buttonName
end
function MouseButton:getDefaults()
    local defaults = {}
    defaults.Position = true
    defaults.Button = true
    return defaults
end
function MouseButton:updatePreviousState(dt)
    self.wasPreviouslyPressed = self.isPressed
    self.previousX = self.x
    self.previousY = self.y
end
function MouseButton:updateState(dt)
    self.isPressed = mouseStateFns[self.buttonName]()
    self.x = GUI.mouseX
    self.y = GUI.mouseY
end

ECS.addSystem(MouseButton)
ECS.addSystem(Position)
ECS.addSystem(Button)

local MouseButtons = {}
for k, v in pairs(mouseStateFns) do
    MouseButtons[k] = {
        MouseButton = true,
        buttonName = k
    }
    ECS.addEntity(MouseButtons[k])
end

return MouseButtons