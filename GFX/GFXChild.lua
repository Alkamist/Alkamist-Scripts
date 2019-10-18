local function GFXChild(GFX)
    local gfxChild = {}

    -- Private Members:

    local _x = 0
    local _y = 0
    local _width = 0
    local _height = 0
    local _isLeftDragging = false
    local _isMiddleDragging = false
    local _isRightDragging = false

    function gfxChild:setLeftDrag(state)   _isLeftDragging = state end
    function gfxChild:setMiddleDrag(state) _isMiddleDragging = state end
    function gfxChild:setRightDrag(state)  _isRightDragging = state end

    -- Getters:

    function gfxChild:getX()      return _x end
    function gfxChild:getY()      return _y end
    function gfxChild:getWidth()  return _width end
    function gfxChild:getHeight() return _height end
    function gfxChild:getMouse()  return GFX:getMouse() end

    function gfxChild:pointIsInside(x, y)
        return x >= self:getX() and x <= self:getX() + self:getWidth()
           and y >= self:getY() and y <= self:getY() + self:getHeight()
    end
    function gfxChild:mouseIsInside()
        return self:pointIsInside(self:getMouse():getX(), self:getMouse():getY())
    end
    function gfxChild:mouseWasInsidePreviously()
        return self:pointIsInside(self:getMouse():getPreviousX(), self:getMouse():getPreviousY())
    end
    function gfxChild:mouseJustEntered() return self:mouseIsInside() and not self:mouseWasInsidePreviously() end
    function gfxChild:mouseJustLeft()    return not self:mouseIsInside() and self:mouseWasInsidePreviously() end
    function gfxChild:isLeftDragging()   return _isLeftDragging end
    function gfxChild:isMiddleDragging() return _isMiddleDragging end
    function gfxChild:isRightDragging()  return _isRightDragging end

    -- Setters:

    function gfxChild:setX(value)      _x = value end
    function gfxChild:setY(value)      _y = value end
    function gfxChild:setWidth(value)  _width = value end
    function gfxChild:setHeight(value) _height = value end

    -- Drawing Code:

    function gfxChild:rect(x, y, width, height, filled)
        gfx.rect(x + self:getX(), y + self:getY(), width, height, filled)
    end
    function gfxChild:line(x, y, x2, y2, antiAliased)
        gfx.line(x + self:getX(),
                 y + self:getY(),
                 x2 + self:getX(),
                 y2 + self:getY(),
                 antiAliased)
    end

    -- Events:

    function gfxChild:onUpdate() end
    function gfxChild:onResize() end
    function gfxChild:onChar(char) end
    function gfxChild:onMouseEnter() end
    function gfxChild:onMouseLeave() end
    function gfxChild:onMouseLeftButtonDown() end
    function gfxChild:onMouseLeftButtonDrag() end
    function gfxChild:onMouseLeftButtonUp() end
    function gfxChild:onMouseMiddleButtonDown() end
    function gfxChild:onMouseMiddleButtonDrag() end
    function gfxChild:onMouseMiddleButtonUp() end
    function gfxChild:onMouseRightButtonDown() end
    function gfxChild:onMouseRightButtonDrag() end
    function gfxChild:onMouseRightButtonUp() end
    function gfxChild:onMouseWheel(numTicks) end
    function gfxChild:onMouseHWheel(numTicks) end
    function gfxChild:onDraw() end

    return gfxChild
end

return GFXChild