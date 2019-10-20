package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local NumberTracker = require("Logic.NumberTracker")

local GFXChild = {}

function GFXChild:new(init)
    local init = init or {}

    local self = setmetatable({}, { __index = self })

    self.x =        NumberTracker(init.x)
    self.y =        NumberTracker(init.y)
    self.width =    NumberTracker(init.width)
    self.height =   NumberTracker(init.height)
    self.mouse =    init.mouse
    self.keyboard = init.keyboard

    return self
end

function GFXChild:updateState(state)
    self.x:update(state.x)
    self.y:update(state.y)
    self.width:update(state.width)
    self.height:update(state.height)
end

function GFXChild:pointIsInside(x, y)
    return x >= self.x and x <= self.x + self.width
       and y >= self.y and y <= self.y + self.height
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

function GFXChild:drawRectangle(x, y, width, height, filled)
    gfx.rect(x + self.x, y + self.y, width, height, filled)
end
function GFXChild:drawLine(x, y, x2, y2, antiAliased)
    gfx.line(x + self.x,
             y + self.y,
             x2 + self.x,
             y2 + self.y,
             antiAliased)
end
function GFXChild:drawCircle(x, y, r, filled, antiAliased)
    gfx.circle(x + self.x,
               y + self.y,
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