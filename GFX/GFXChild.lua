package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local NumberTracker = require("Logic.NumberTracker")

local GFXChild = {}

function GFXChild:new(init)
    local init = init or {}

    local self = setmetatable({}, { __index = self })

    self.GFX =      init.GFX
    self.mouse =    {}
    self.keyboard = {}
    self.x =        NumberTracker:new(init.x)
    self.y =        NumberTracker:new(init.y)
    self.width =    NumberTracker:new(init.width)
    self.height =   NumberTracker:new(init.height)

    self.relativeMouseX = NumberTracker:new(0)
    self.relativeMouseY = NumberTracker:new(0)

    return self
end

function GFXChild:updateState(state)
    self.x:update(state.x)
    self.y:update(state.y)
    self.width:update(state.width)
    self.height:update(state.height)

    self.relativeMouseX:update(self.mouse.x.current - self.x.current)
    self.relativeMouseY:update(self.mouse.y.current - self.y.current)
end

function GFXChild:pointIsInside(x, y)
    return x >= self.x.current and x <= self.x.current + self.width.current
       and y >= self.y.current and y <= self.y.current + self.height.current
end
function GFXChild:mouseIsInside()
    return self:pointIsInside(self.mouse.x.current, self.mouse.y.current)
end
function GFXChild:mouseWasInsidePreviously()
    return self:pointIsInside(self.mouse.x.previous, self.mouse.y.previous)
end
function GFXChild:mouseJustEntered() return self:mouseIsInside() and not self:mouseWasInsidePreviously() end
function GFXChild:mouseJustLeft()    return not self:mouseIsInside() and self:mouseWasInsidePreviously() end

-- Drawing Code:

function GFXChild:setColor(color)
    gfx.set(color[1], color[2], color[3], color[4])
end
function GFXChild:drawRectangle(x, y, width, height, filled)
    gfx.rect(x + self.x.current, y + self.y.current, width, height, filled)
end
function GFXChild:drawLine(x, y, x2, y2, antiAliased)
    gfx.line(x + self.x.current,
             y + self.y.current,
             x2 + self.x.current,
             y2 + self.y.current,
             antiAliased)
end
function GFXChild:drawCircle(x, y, r, filled, antiAliased)
    gfx.circle(x + self.x.current,
               y + self.y.current,
               r,
               filled,
               antiAliased)
end

-- Events:

function GFXChild:onUpdate() end
function GFXChild:onResize() end
function GFXChild:onKeyPress() end
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
function GFXChild:onMouseWheel() end
function GFXChild:onMouseHWheel() end
function GFXChild:onDraw() end

return GFXChild