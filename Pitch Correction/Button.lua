local Button = {}

function Button.new(isPressed)
    local self = {}

    self.isPressed = isPressed
    self.wasPreviouslyPressed = isPressed

    function self:justPressed() return self.isPressed and not self.wasPreviouslyPressed end
    function self:justReleased() return not self.isPressed and self.wasPreviouslyPressed end
    function self:update() self.wasPreviouslyPressed = self.isPressed end

    return self
end

return Button