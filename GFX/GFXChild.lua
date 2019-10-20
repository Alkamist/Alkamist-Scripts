local GFXChild = {}

function GFXChild:new(init)
    local init = init or {}
    if init.gfxAPI == nil then return nil end

    local self = setmetatable({}, { __index = self })

    self._gfxAPI = init.gfxAPI
    self._x =      init.x or 0
    self._y =      init.y or 0
    self._width =  init.width or 0
    self._height = init.height or 0

    self._leftDragEnabled = false
    self._middleDragEnabled = false
    self._rightDragEnabled = false
    self._isLeftDragging = false
    self._isMiddleDragging = false
    self._isRightDragging = false

    return self
end

-- Functions you should not call:

function GFXChild:enableLeftDrag(state)       self._leftDragEnabled = state end
function GFXChild:enableMiddleDrag(state)     self._middleDragEnabled = state end
function GFXChild:enableRightDrag(state)      self._rightDragEnabled = state end
function GFXChild:markAsLeftDragging(state)   self._isLeftDragging = state end
function GFXChild:markAsMiddleDragging(state) self._isMiddleDragging = state end
function GFXChild:markAsRightDragging(state)  self._isRightDragging = state end
function GFXChild:isLeftDragEnabled(state)    return self._leftDragEnabled end
function GFXChild:isMiddleDragEnabled(state)  return self._middleDragEnabled end
function GFXChild:isRightDragEnabled(state)   return self._rightDragEnabled end

-- Getters:

function GFXChild:getGFXAPI() return self._gfxAPI end
function GFXChild:getX()      return self._x end
function GFXChild:getY()      return self._y end
function GFXChild:getWidth()  return self._width end
function GFXChild:getHeight() return self._height end
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
function GFXChild:isLeftDragging()   return self._isLeftDragging end
function GFXChild:isMiddleDragging() return self._isMiddleDragging end
function GFXChild:isRightDragging()  return self._isRightDragging end

-- Setters:

function GFXChild:setX(value)      self._x = value end
function GFXChild:setY(value)      self._y = value end
function GFXChild:setWidth(value)  self._width = value end
function GFXChild:setHeight(value) self._height = value end

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