local tiny = require("tiny")

local ButtonDrag = tiny.processingSystem()

ButtonDrag.filter = tiny.requireAll(
    "isPressed", "justReleased", "justMoved"
)

function ButtonDrag:process(e, dt)
    self.justDragged = self.isPressed and self.justMoved
    self.justStartedDragging = self.justDragged and not self.hasDraggedSincePress
    self.justStoppedDragging = self.justReleased and self.hasDraggedSincePress
    if self.justDragged then self.hasDraggedSincePress = true end
    if self.justReleased then self.hasDraggedSincePress = false end
end

return ButtonDrag