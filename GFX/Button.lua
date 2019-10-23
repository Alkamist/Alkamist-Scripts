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

function Button:handleMouseEnter()    self:queueRedraw() end
function Button:handleMouseLeave()    self:queueRedraw() end
function Button:handleMouseLeftDown() self:queueRedraw() end
function Button:handleMouseLeftUp()   self:queueRedraw() end

function Button:onUpdate()
    if self.mouseJustEntered then self:handleMouseEnter() end
    if self.mouseJustLeft    then self:handleMouseLeave() end
    if self.mouseLeftDown    then self:handleMouseLeftDown() end
    if self.mouseLeftUp      then self:handleMouseLeftUp() end
end
function Button:onDraw()
    self:setColor(self.color)
    self:drawRectangle(0, 0, self.w, self.h, true)

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
end

return Button