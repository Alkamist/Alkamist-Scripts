local Position = {}

function Position.filter(system, entity)
    return entity.Position
end
function Position:getDefaults()
    local defaults = {}

    defaults.x = 0
    defaults.previousX = 0
    defaults.xChange = 0
    defaults.xJustChanged = false

    defaults.y = 0
    defaults.previousY = 0
    defaults.yChange = 0
    defaults.yJustChanged = false

    defaults.justMoved = false

    return defaults
end
function Position:updatePreviousState(dt)
    self.previousX = self.x
    self.previousY = self.y
end
function Position:updateState(dt)
    self.xChange = self.x - self.previousX
    self.xJustChanged = self.x ~= self.previousX
    self.yChange = self.y - self.previousY
    self.yJustChanged = self.y ~= self.previousY
    self.justMoved = self.xJustChanged or self.yJustChanged
end

return Position