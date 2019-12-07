local tiny = require("tiny")

local ButtonState = tiny.processingSystem()

ButtonState.filter = tiny.requireAll(
    "isPressed", "wasPreviouslyPressed"
)

function ButtonState:process(e, dt)
    self.justPressed = self.isPressed and not self.wasPreviouslyPressed
    self.justReleased = not self.isPressed and self.wasPreviouslyPressed
end

--function Button:justDraggedObject(object) return Button.wasPressedInsideObject(self, object) and Button.justDragged(self) end
--function Button:justStartedDraggingObject(object) return Button.wasPressedInsideObject(self, object) and Button.justStartedDragging(self) end
--function Button:justStoppedDraggingObject(object) return Button.wasPressedInsideObject(self, object) and Button.justStoppedDragging(self) end

return ButtonState