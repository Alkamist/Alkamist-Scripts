local Button = {}

function Button:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.x = init.x or 0
    self.y = init.y or 0
    self.w = init.w or 0
    self.h = init.h or 0

    self.label =          init.label or ""
    self.labelFont =      init.labelFont or "Arial"
    self.labelFontSize =  init.labelFontSize or 14


    self.color =          init.color          or {0.4, 0.4, 0.4, 1.0,   0}
    self.edgeColor =      init.edgeColor      or {1.0, 1.0, 1.0, 0.1,   1}
    self.mouseOverColor = init.mouseOverColor or {1.0, 1.0, 1.0, 0.15,  1}
    self.mouseHoldColor = init.mouseHoldColor or {1.0, 1.0, 1.0, -0.15, 1}
    self.labelColor =     init.labelColor     or {1.0, 1.0, 1.0, 0.4,   1}

    return self
end

function Button:drawLabel()
    self:setColor(self.labelColor)
    self:setFont(self.labelFont, self.labelFontSize)
    self:drawString(self.label, 0, 0, 5, self.w, self.h)
end

function Button:onMouseEnter()    self:queueRedraw() end
function Button:onMouseLeave()    self:queueRedraw() end
function Button:onMouseLeftDown() self:queueRedraw() end
function Button:onMouseLeftUp()   self:queueRedraw() end
function Button:onDraw()
    self:setColor(self.color)
    self:drawRectangle(0, 0, self.w, self.h, true)

    self:setColor(self.edgeColor)
    self:drawRoundRectangle(0, 0, self.w, self.h, 2, false, true)

    self:drawLabel()

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