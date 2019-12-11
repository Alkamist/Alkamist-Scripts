local GUI = require("GUI")

local Rectangle = {}

function Rectangle:requires()
    return self.Rectangle
end
function Rectangle:getDefaults()
    local defaults = {}
    defaults.x = 0
    defaults.y = 0
    defaults.width = 0
    defaults.height = 0
    defaults.mouseIsInside = false
    return defaults
end
function Rectangle:update(dt)
    local x, y, w, h = self.x, self.y, self.width, self.height
    local mouseX, mouseY = GUI.mouseX, GUI.mouseY

    self.mouseIsInside = mouseX >= x and mouseX <= x + w
                     and mouseY >= y and mouseY <= y + h
end

return Rectangle