local Widget = {}

function Widget:initialize()
    self.x = 0
    self.y = 0
    self.previousX = 0
    self.previousY = 0
    self.width = 0
    self.height = 0
end

function Widget:justMoved()
    return self.x ~= self.previousX or self.y ~= self.previousY
end
function Widget:pointIsInside(point)
    return point.x >= self.x and point.x <= self.x + self.width
       and point.y >= self.y and point.y <= self.y + self.height
end
function Widget:beginUpdate()
end
function Widget:draw()
    local x, y, a, mode, dest = gfx.x, gfx.y, gfx.a, gfx.mode, gfx.dest

    if self.draw then self:draw() end

    gfx.x, gfx.y, gfx.a, gfx.mode, gfx.dest = x, y, a, mode, dest
end
function Widget:endUpdate()
    self.previousX = self.x
    self.previousY = self.y
end

return Widget