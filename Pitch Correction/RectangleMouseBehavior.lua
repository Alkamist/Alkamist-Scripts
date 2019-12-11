local GUI = require("GUI")

local RectangleMouseBehavior = {}

function RectangleMouseBehavior:requires()
    return self.RectangleMouseBehavior
end
function RectangleMouseBehavior:getDefaults()
    local defaults = {}
    defaults.x = 0
    defaults.y = 0
    defaults.width = 0
    defaults.height = 0
    defaults.mouseIsInside = false
    return defaults
end
function RectangleMouseBehavior:update(dt)
    local x, y, w, h = self.x, self.y, self.width, self.height
    local mouseX, mouseY = GUI.mouseX, GUI.mouseY
    self.mouseIsInside = mouseX >= x and mouseX <= x + w
                     and mouseY >= y and mouseY <= y + h
end

return RectangleMouseBehavior