local Button = {}

function Button:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.x = init.x or 0
    self.y = init.y or 0
    self.w = init.w or 0
    self.h = init.h or 0

    self.color =     init.color or {0.4, 0.4, 0.4, 1.0}
    self.edgeColor =      {1.0, 1.0, 1.0, 0.1}
    self.mouseOverColor = {1.0, 1.0, 1.0, 0.2}
    self.mouseHoldColor = {0.0, 0.0, 0.0, 0.3}

    return self
end

function Button:onMouseEnter()
    self:queueRedraw()
end
function Button:onMouseLeave()
    self:queueRedraw()
end
function Button:onMouseLeftButtonDown()
    self:queueRedraw()
end
function Button:onMouseLeftButtonUp()
    self:queueRedraw()
end

function Button:onDraw()
    self:setColor(self.color)
    self:drawRectangle(0, 0, self.w, self.h, true)

    self:setColor(self.edgeColor)
    self:drawRoundRectangle(0, 0, self.w, self.h, 2, false, true)

    if self.mouseIsInside then
        if self.GFX.leftState then
            self:setColor(self.mouseHoldColor)
        else
            self:setColor(self.mouseOverColor)
        end
        self:drawRectangle(0, 0, self.w, self.h, true)
    end
end

return Button