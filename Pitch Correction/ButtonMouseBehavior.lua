local GUI = require("GUI")

local ButtonMouseBehavior = {}

function ButtonMouseBehavior:requires()
    return self.ButtonMouseBehavior
end
function ButtonMouseBehavior:getDefaults()
    local defaults = {}
    defaults.isPressed = false
    defaults.mouseIsInside = false
    return defaults
end
function ButtonMouseBehavior:update(dt)
    if self.mouseIsInside and GUI.leftMouseButtonJustPressed then
        self.isPressed = true
    end
    if GUI.leftMouseButtonJustReleased and self.isPressed then
        self.isPressed = false
    end
end

return ButtonMouseBehavior