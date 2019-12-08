local tiny = require("tiny")

local ButtonState = tiny.processingSystem()

ButtonState.filter = tiny.requireAll(
    "isPressed", "wasPreviouslyPressed"
)

--function ButtonState:getDefault()
--    local e = {}
--    e.isPressed = false
--    e.wasPreviouslyPressed = false
--    e.justPressed = false
--    e.justReleased = false
--    return e
--end

function ButtonState:process(e, dt)
    e.justPressed = e.isPressed and not e.wasPreviouslyPressed
    e.justReleased = not e.isPressed and e.wasPreviouslyPressed
end

--function Button:justDraggedObject(object) return Button.wasPressedInsideObject(self, object) and Button.justDragged(self) end
--function Button:justStartedDraggingObject(object) return Button.wasPressedInsideObject(self, object) and Button.justStartedDragging(self) end
--function Button:justStoppedDraggingObject(object) return Button.wasPressedInsideObject(self, object) and Button.justStoppedDragging(self) end

return ButtonState