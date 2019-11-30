local setProperty = require("Properties").setProperty

local Button = {}

function Button.new(isPressed)
    local self = {}

    self.isPressed = isPressed
    self.wasPreviouslyPressed = isPressed

    setProperty(self, "justPressed", { get = function(self) return self.isPressed and not self.wasPreviouslyPressed end })
    setProperty(self, "justReleased", { get = function(self) return not self.isPressed and self.wasPreviouslyPressed end })

    function self:update() self.wasPreviouslyPressed = self.isPressed end

    return self
end

return Button