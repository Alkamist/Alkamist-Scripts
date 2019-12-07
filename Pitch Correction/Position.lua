local tiny = require("tiny")

local Position = tiny.processingSystem()

Position.filter = tiny.requireAll(
    "x", "y", "previousX", "previousY"
)

function Position:process(e, dt)
    e.xChange = e.x - e.previousX
    e.xJustChanged = e.x ~= e.previousX
    e.yChange = e.y - e.previousY
    e.yJustChanged = e.y ~= e.previousY
    e.justMoved = e.xJustChanged or e.yJustChanged
end

return Position