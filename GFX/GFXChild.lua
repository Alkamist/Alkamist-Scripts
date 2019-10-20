local GFXChild = {}

function GFXChild:new(init)
    local init = init or {}
    --if init.GFX == nil then return nil end

    local self = setmetatable({}, { __index = self })

    self.GFX =    init.GFX
    self.x =      init.x or 0
    self.y =      init.y or 0
    self.width =  init.width or 0
    self.height = init.height or 0

    self.relativeMouseX = 0
    self.relativeMouseY = 0

    self.leftDragEnabled = false
    self.middleDragEnabled = false
    self.rightDragEnabled = false
    self.leftDragState = false
    self.middleDragState = false
    self.rightDragState = false

    return self
end

-- Functions you should not call:

function GFXChild:enableLeftDrag(state)       self.leftDragEnabled = state end
function GFXChild:enableMiddleDrag(state)     self.middleDragEnabled = state end
function GFXChild:enableRightDrag(state)      self.rightDragEnabled = state end
function GFXChild:markAsLeftDragging(state)   self.leftDragState = state end
function GFXChild:markAsMiddleDragging(state) self.middleDragState = state end
function GFXChild:markAsRightDragging(state)  self.rightDragState = state end
function GFXChild:isLeftDragEnabled(state)    return self.leftDragEnabled end
function GFXChild:isMiddleDragEnabled(state)  return self.middleDragEnabled end
function GFXChild:isRightDragEnabled(state)   return self.rightDragEnabled end

-- Getters:

function GFXChild:getGFX()    return self.GFX end
function GFXChild:getX()      return self.x end
function GFXChild:getY()      return self.y end
function GFXChild:getWidth()  return self.width end
function GFXChild:getHeight() return self.height end
function GFXChild:getMouse()  return self.GFX:getMouse() end

function GFXChild:updateRelativeMouseX()
    local mouse = self:getMouse()
    self.relativeMouseX = mouse:getX() - self:getX()
end
function GFXChild:updateRelativeMouseY()
    local mouse = self:getMouse()
    self.relativeMouseY = mouse:getY() - self:getY()
end
function GFXChild:getRelativeMouseX() return self.relativeMouseX end
function GFXChild:getRelativeMouseY() return self.relativeMouseY end

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
function GFXChild:isLeftDragging()   return self.leftDragState end
function GFXChild:isMiddleDragging() return self.middleDragState end
function GFXChild:isRightDragging()  return self.rightDragState end

-- Setters:

function GFXChild:setX(value)      self.x = value end
function GFXChild:setY(value)      self.y = value end
function GFXChild:setWidth(value)  self.width = value end
function GFXChild:setHeight(value) self.height = value end

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
function GFXChild:circle(x, y, r, filled, antiAliased)
    gfx.circle(x + self:getX(),
               y + self:getY(),
               r,
               filled,
               antiAliased)
end

-- Events:

function GFXChild:onUpdate()
    self:updateRelativeMouseX()
    self:updateRelativeMouseY()
end
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