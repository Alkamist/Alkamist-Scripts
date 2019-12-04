local Button = require("Button")

local MovingButton = {}

function MovingButton:new(object)
    local object = object or {}
    local defaults = {
        x = 0,
        previousX = 0,
        y = 0,
        previousY = 0,
        justMoved = false,
        justDragged = false,
        justStartedDragging = false,
        justStoppedDragging = false,
        hasDraggedSincePress = false
    }

    for k, v in pairs(defaults) do if object[k] == nil then object[k] = v end end
    for k, v in pairs(self) do if object[k] == nil then object[k] = v end end
    return Button:new(object)
end

function MovingButton:update()
    Button.update(self)

    self.justMoved = self.x ~= self.previousX or self.y ~= self.previousY
    self.justDragged = self.isPressed and self.justMoved
    self.justStartedDragging = self.justDragged and not self.hasDraggedSincePress
    self.justStoppedDragging = self.justReleased and self.hasDraggedSincePress
    if self.justDragged then self.hasDraggedSincePress = true end
    if self.justReleased then self.hasDraggedSincePress = false end
end

return MovingButton