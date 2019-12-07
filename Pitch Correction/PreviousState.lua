local tiny = require("tiny")

local PreviousState = tiny.processingSystem()

PreviousState.filter = tiny.requireAny(
    "isPressed", "x", "y"
)

function PreviousState:process(e, dt)
    e.wasPreviouslyPressed = e.isPressed
    e.previousX = e.x
    e.previousY = e.y
end

return PreviousState