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

return MouseButton