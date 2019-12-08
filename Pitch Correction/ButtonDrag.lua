local tiny = require("tiny")

local ButtonDrag = tiny.processingSystem()

ButtonDrag.filter = tiny.requireAll(
    "isPressed", "justReleased", "justMoved"
)

--function ButtonDrag:getDefault()
--    local e = {}
--    e.isPressed = false
--    e.justReleased = false
--    e.justMoved = false
--    e.justDragged = false
--    e.justStartedDragging = false
--    e.justStoppedDragging = false
--    e.hasDraggedSincePress = false
--    return e
--end

function ButtonDrag:process(e, dt)
    e.justDragged = e.isPressed and e.justMoved
    e.justStartedDragging = e.justDragged and not e.hasDraggedSincePress
    e.justStoppedDragging = e.justReleased and e.hasDraggedSincePress
    if e.justDragged then e.hasDraggedSincePress = true end
    if e.justReleased then e.hasDraggedSincePress = false end
end

return ButtonDrag