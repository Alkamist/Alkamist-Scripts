local MovingButton = require("MovingButton")

local ControlledButton = {}

function ControlledButton:new(object)
    local object = object or {}
    local defaults = {
        width = 0,
        height = 0,
        pressControl = nil,
        toggleControl = nil
    }

    for k, v in pairs(defaults) do if object[k] == nil then object[k] = v end end
    for k, v in pairs(self) do if object[k] == nil then object[k] = v end end
    return MovingButton:new(object)
end

function ControlledButton:pointIsInside(point)
    return point.x >= self.x and point.y <= self.x + self.width
       and point.y >= self.y and point.y <= self.y + self.height
end

function ControlledButton:update()
    MovingButton.update(self)

    local pressControl = self.pressControl
    local toggleControl = self.toggleControl

    if pressControl then
        if self:pointIsInside(pressControl) and pressControl.justPressed then
            self.isPressed = true
        end
        if pressControl.justReleased then
            self.isPressed = false
        end
    end

    if toggleControl then
        if self:pointIsInside(toggleControl) and toggleControl.justPressed then
            self.isPressed = not self.isPressed
        end
    end
end

return ControlledButton