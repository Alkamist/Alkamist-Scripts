local Button = {}

function Button:new(object)
    local object = object or {}
    local defaults = {
        isPressed = false,
        wasPreviouslyPressed = false,
        justPressed = false,
        justReleased = false
    }

    for k, v in pairs(defaults) do if object[k] == nil then object[k] = v end end
    for k, v in pairs(self) do if object[k] == nil then object[k] = v end end
    return object
end

function Button:update()
    self.justPressed = self.isPressed and not self.wasPreviouslyPressed
    self.justReleased = not self.isPressed and self.wasPreviouslyPressed
end

return Button