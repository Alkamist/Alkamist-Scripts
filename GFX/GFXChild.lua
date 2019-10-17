package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GFX = require "GFX.Alkamist GFX"

local GFXChild = {}

function GFXChild:init()
    self.x = self.x or 0
    self.y = self.y or 0
    self.w = self.w or 0
    self.h = self.h or 0
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

---------------------- Events ----------------------

function GFXChild:pointIsInside(point)
    return point.x >= self.x and point.x <= self.x + self.w
       and point.y >= self.y and point.y <= self.y + self.h
end
function GFXChild:mouseIsInside()
    return self:pointIsInside({ x = GFX.mouseX, y = GFX.mouseY })
end
function GFXChild:mouseJustEntered()
    return self:pointIsInside({ x = GFX.mouseX, y = GFX.mouseY })
    and (not self:pointIsInside({ x = GFX.prevMouseX, y = GFX.prevMouseY }) )
end
function GFXChild:mouseJustLeft()
    return ( not self:pointIsInside({ x = GFX.mouseX, y = GFX.mouseY }) )
       and self:pointIsInside({ x = GFX.prevMouseX, y = GFX.prevMouseY })
end
function GFXChild:onUpdate() end
function GFXChild:onResize() end
function GFXChild:onChar(char) end
function GFXChild:onMouseEnter() end
function GFXChild:onMouseLeave() end
function GFXChild:onLeftMouseDown() end
function GFXChild:onLeftMouseUp() end
function GFXChild:onLeftMouseDrag() end
function GFXChild:onMiddleMouseDown() end
function GFXChild:onMiddleMouseUp() end
function GFXChild:onMiddleMouseDrag() end
function GFXChild:onRightMouseDown() end
function GFXChild:onRightMouseUp() end
function GFXChild:onRightMouseDrag() end
function GFXChild:onMouseWheel(numTicks) end
function GFXChild:onMouseHWheel(numTicks) end
function GFXChild:draw() end

return GFXChild