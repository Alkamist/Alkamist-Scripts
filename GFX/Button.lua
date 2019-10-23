local Button = {}

function Button:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.x = init.x or 0
    self.y = init.y or 0
    self.w = init.w or 0
    self.h = init.h or 0

    self.color = init.color or {0.4, 0.4, 0.4, 1.0}
    self.edgeColor =           {1.0, 1.0, 1.0, 0.1}
    self.mouseOverColor =      {1.0, 1.0, 1.0, 0.15}
    self.mouseHoldColor =      {1.0, 1.0, 1.0, -0.15}

    return self
end

function Button:onMouseEnter()    self:queueRedraw() end
function Button:onMouseLeave()    self:queueRedraw() end
function Button:onMouseLeftDown() self:queueRedraw() end
function Button:onMouseLeftUp()   self:queueRedraw() end

function Button:onDraw()
    self:setBlendMode(0)
    self:setColor(self.color)
    self:drawRectangle(0, 0, self.w, self.h, true)

    self:setBlendMode(1)
    self:setColor(self.edgeColor)
    self:drawRoundRectangle(0, 0, self.w, self.h, 2, false, true)

    if self.mouseLeftState then
        self:setColor(self.mouseHoldColor)
    else
        self:setColor(self.mouseOverColor)
    end

    if self.mouseIsInside or self.mouseLeftState then
        self:drawRectangle(0, 0, self.w, self.h, true)
    end
    self:setBlendMode(0)
end

return Button