local Position = {}

function Position:new()
    local self = self or {}
    for k, v in pairs(Position) do self[k] = v end
    self:setX(0)
    self:setPreviousX(0)
    self:setY(0)
    self:setPreviousY(0)
    return self
end

function Position:getX() return self._x end
function Position:setX(v) self._x = v end
function Position:getPreviousX() return self._previousX end
function Position:setPreviousX(v) self._previousX = v end
function Position:getY() return self._y end
function Position:setY(v) self._y = v end
function Position:getPreviousY() return self._previousY end
function Position:setPreviousY(v) self._previousY = v end

function Position:justMoved() return self:getX() ~= self:getPreviousX() or self:getY() ~= self:getPreviousY() end

function Position:update(dt)
    self:setPreviousX(self:getX())
    self:setPreviousY(self:getY())
end

return Position