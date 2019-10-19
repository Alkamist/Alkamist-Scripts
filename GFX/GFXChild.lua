local GFXChild = {}

function GFXChild:new(gfxAPI)
    if gfxAPI == nil then return nil end

    local instance = {}
    instance._gfxAPI = gfxAPI
    instance._x = 0
    instance._y = 0
    instance._width = 0
    instance._height = 0
    instance._isLeftDragging = false
    instance._isMiddleDragging = false
    instance._isRightDragging = false

    return setmetatable(instance, { __index = self })
end

function GFXChild:setLeftDrag(state)   _isLeftDragging = state end
function GFXChild:setMiddleDrag(state) _isMiddleDragging = state end
function GFXChild:setRightDrag(state)  _isRightDragging = state end

-- Getters:

function GFXChild:getX()      return _x end
function GFXChild:getY()      return _y end
function GFXChild:getWidth()  return _width end
function GFXChild:getHeight() return _height end
function GFXChild:getMouse()  return self._gfxAPI:getMouse() end

function GFXChild:pointIsInside(x, y)
    return x >= self:getX() and x <= self:getX() + self:getWidth()
        and y >= self:getY() and y <= self:getY() + self:getHeight()
end
function GFXChild:mouseIsInside()
    return self:pointIsInside(self:getMouse():getX(), self:getMouse():getY())
end
function GFXChild:mouseWasInsidePreviously()
    return self:pointIsInside(self:getMouse():getPreviousX(), self:getMouse():getPreviousY())
end
function GFXChild:mouseJustEntered() return self:mouseIsInside() and not self:mouseWasInsidePreviously() end
function GFXChild:mouseJustLeft()    return not self:mouseIsInside() and self:mouseWasInsidePreviously() end
function GFXChild:isLeftDragging()   return _isLeftDragging end
function GFXChild:isMiddleDragging() return _isMiddleDragging end
function GFXChild:isRightDragging()  return _isRightDragging end

-- Setters:

function GFXChild:setX(value)      _x = value end
function GFXChild:setY(value)      _y = value end
function GFXChild:setWidth(value)  _width = value end
function GFXChild:setHeight(value) _height = value end

-- Drawing Code:

function GFXChild:rect(x, y, width, height, filled)
    gfx.rect(x + self:getX(), y + self:getY(), width, height, filled)
end
function GFXChild:line(x, y, x2, y2, antiAliased)
    gfx.line(x + self:getX(),
                y + self:getY(),
                x2 + self:getX(),
                y2 + self:getY(),
                antiAliased)
end

-- Events:

function GFXChild:onUpdate() end
function GFXChild:onResize() end
function GFXChild:onChar(char) end
function GFXChild:onMouseEnter() end
function GFXChild:onMouseLeave() end
function GFXChild:onMouseLeftButtonDown() end
function GFXChild:onMouseLeftButtonDrag() end
function GFXChild:onMouseLeftButtonUp() end
function GFXChild:onMouseMiddleButtonDown() end
function GFXChild:onMouseMiddleButtonDrag() end
function GFXChild:onMouseMiddleButtonUp() end
function GFXChild:onMouseRightButtonDown() end
function GFXChild:onMouseRightButtonDrag() end
function GFXChild:onMouseRightButtonUp() end
function GFXChild:onMouseWheel(numTicks) end
function GFXChild:onMouseHWheel(numTicks) end
function GFXChild:onDraw() end

return GFXChild