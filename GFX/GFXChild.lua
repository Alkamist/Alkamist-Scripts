package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GFX = require "GFX.Alkamist GFX"

local GFXChild = {}

function GFXChild:init()
    self.x = self.x or 0
    self.y = self.y or 0
    self.w = self.w or 0
    self.h = self.h or 0
end

function GFXChild:getRelativeMouseX()
    return self.relativeMouseX
end
function GFXChild:getRelativeMouseY()
    return self.relativeMouseY
end
function GFXChild:getPrevRelativeMouseX()
    return self.prevRelativeMouseX
end
function GFXChild:getPrevRelativeMouseY()
    return self.prevRelativeMouseY
end

---------------------- Drawing Code ----------------------

function GFXChild:rect(x, y, w, h, filled)
    gfx.rect(x + self.x, y + self.y, w, h, filled)
end
function GFXChild:line(x, y, x2, y2, antiAliased)
    gfx.line(x + self.x,
             y + self.y,
             x2 + self.x,
             y2 + self.y,
             antiAliased)
end

---------------------- Information Functions ----------------------

function GFXChild:pointIsInside(point)
    return point.x >= self.x and point.x <= self.x + self.w
       and point.y >= self.y and point.y <= self.y + self.h
end
function GFXChild:mouseIsInside()
    return self:pointIsInside({ x = GFX.mouse:getX(), y = GFX.mouse:getY() })
end
function GFXChild:mouseJustEntered()
    return self:pointIsInside({ x = GFX.mouse:getX(), y = GFX.mouse:getY() })
    and (not self:pointIsInside({ x = GFX.mouse:getPrevX(), y = GFX.mouse:getPrevY() }) )
end
function GFXChild:mouseJustLeft()
    return ( not self:pointIsInside({ x = GFX.mouse:getX(), y = GFX.mouse:getY() }) )
       and self:pointIsInside({ x = GFX.mouse:getPrevX(), y = GFX.mouse:getPrevY() })
end
function GFXChild:mouseLeftButtonWasDragged()
    return self._mouseLeftButtonWasDragged
end
function GFXChild:mouseMiddleButtonWasDragged()
    return self._mouseMiddleButtonWasDragged
end
function GFXChild:mouseRightButtonWasDragged()
    return self._mouseRightButtonWasDragged
end

---------------------- Events ----------------------

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
function GFXChild:draw() end

return GFXChild