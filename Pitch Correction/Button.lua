local Button = {}

function Button:new(o)
    local self = setmetatable(o or {}, { __index = self })
    self:initialize()
    return self
end

function Button:initialize()
    local defaults = {
        isPressed = false,
        wasPreviouslyPressed = false,
        justPressed = false,
        justReleased = false
    }

    for k, v in pairs(defaults) do
        if self[k] == nil then
            self[k] = v
        end
    end
end

function Button:update()
    self.justPressed = self.isPressed and not self.wasPreviouslyPressed
    self.justReleased = not self.isPressed and self.wasPreviouslyPressed
end

return Button