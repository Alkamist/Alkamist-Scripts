local tiny = require("tiny")

local Position = tiny.processingSystem()

Position.filter = tiny.requireAll(
    "x", "y", "previousX", "previousY"
)

function Position:process(e, dt)
    e.xChange = self.x - self.previousX
    e.xJustChanged = self.x ~= self.previousX
    e.yChange = self.y - self.previousY
    e.yJustChanged = self.y ~= self.previousY
    e.justMoved = e.xJustChanged or e.yJustChanged
end

return Position