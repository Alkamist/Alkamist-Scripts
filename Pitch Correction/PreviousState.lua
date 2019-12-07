local tiny = require("tiny")

local PreviousState = tiny.processingSystem()

PreviousState.filter = tiny.requireAll(
    "isPressed"
)

function PreviousState:process(e, dt)
    self.wasPreviouslyPressed = self.isPressed
end

return PreviousState