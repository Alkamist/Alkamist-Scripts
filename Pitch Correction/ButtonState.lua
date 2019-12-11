local GUI = require("GUI")

local ButtonState = {}

function ButtonState:requires()
    return self.ButtonState
end
function ButtonState:getDefaults()
    local defaults = {}
    defaults.isPressed = false
    defaults.mouseIsInside = false
    return defaults
end
function ButtonState:update(dt)
    if self.mouseIsInside and GUI.leftMouseButtonJustPressed then
        self.isPressed = true
    end
    if GUI.leftMouseButtonJustReleased and self.isPressed then
        self.isPressed = false
    end
end

return ButtonState