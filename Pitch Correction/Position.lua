return function(self)
    local self = self or {}
    if self.Position then return self end
    self.Position = true

    local _x, _y, _previousX, _previousY

    function self.getX() return _x end
    function self.setX(v) _x = v end
    function self.getPreviousX() return _previousX end
    function self.setPreviousX(v) _previousX = v end
    function self.getY() return _y end
    function self.setY(v) _y = v end
    function self.getPreviousY() return _previousY end
    function self.setPreviousY(v) _previousY = v end

    function self.getXChange() return self.getX() - self.getPreviousX() end
    function self.xChanged() return self.getX() ~= self.getPreviousX() end
    function self.getYChange() return self.getY() - self.getPreviousY() end
    function self.yChanged() return self.getY() ~= self.getPreviousY() end
    function self.justMoved() return self.xChanged() or self.yChanged() end

    function self.updateState(dt) end
    function self.updatePreviousState(dt)
        self.setPreviousX(self.getX())
        self.setPreviousY(self.getY())
    end

    self.setX(0)
    self.setPreviousX(0)
    self.setY(0)
    self.setPreviousY(0)

    return self
end