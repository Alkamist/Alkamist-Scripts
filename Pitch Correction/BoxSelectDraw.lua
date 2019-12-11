local GUI = require("GUI")

local BoxSelectDraw = {}

function BoxSelectDraw:getDefaults()
    local defaults = {}
    defaults.x = 0
    defaults.y = 0
    defaults.width = 0
    defaults.height = 0
    defaults.isActive = false
    defaults.bodyColor = { 1, 1, 1, -0.04, 1 }
    defaults.outlineColor = { 1, 1, 1, 0.3, 1 }
    return defaults
end
function BoxSelectDraw:filter()
    return self.BoxSelectDraw
end
function BoxSelectDraw:update(dt)
    local x, y, w, h = self.x, self.y, self.width, self.height

    if self.isActive then
        -- Draw the body.
        GUI.setColor(self.bodyColor)
        GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, true)

        -- Draw the outline.
        GUI.setColor(self.outlineColor)
        GUI.drawRectangle(x, y, w, h, false)
    end
end

return BoxSelectDraw