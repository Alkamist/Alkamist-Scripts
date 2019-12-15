local pairs = pairs
local table = table

local Button = {}

function Button:new()
    local self = self or {}

    local defaults = {}
    defaults.x = 0
    defaults.y = 0
    defaults.width = 0
    defaults.height = 0
    defaults.isPressed = false
    defaults.bodyColor = { 0.4, 0.4, 0.4, 1, 0 }
    defaults.outlineColor = { 0.15, 0.15, 0.15, 1, 0 }
    defaults.pressedColor = { 1, 1, 1, -0.1, 1 }
    defaults.highlightColor = { 1, 1, 1, 0.1, 1 }

    for k, v in pairs(defaults) do if self[k] == nil then self[k] = v end end
    for k, v in pairs(Button) do if self[k] == nil then self[k] = v end end
    return self
end
function Button:pointIsInside(pointX, pointY)
    local x, y, w, h = self.x, self.y, self.width, self.height
    return pointX >= x and pointX <= x + w
       and pointY >= y and pointY <= y + h
end
function Button:update()
    if self.mouse.buttons.left:justPressedWidget(self) then self.isPressed = true end
    if self.mouse.buttons.left:justReleasedWidget(self) then self.isPressed = false end
    self.isGlowing = self:pointIsInside(self.mouse.x, self.mouse.y)
end
function Button:draw()
    local setColor = self.setColor
    local drawRectangle = self.drawRectangle
    local x, y, w, h = self.x, self.y, self.width, self.height
    local bodyColor, outlineColor, highlightColor, pressedColor = self.bodyColor, self.outlineColor, self.highlightColor, self.pressedColor

    -- Draw the body.
    setColor(self, bodyColor)
    drawRectangle(self, x + 1, y + 1, w - 2, h - 2, true)

    -- Draw a dark outline around.
    setColor(self, outlineColor)
    drawRectangle(self, x, y, w, h, false)

    -- Draw a light outline around.
    setColor(self, highlightColor)
    drawRectangle(self, x + 1, y + 1, w - 2, h - 2, false)

    if self.isPressed then
        setColor(self, pressedColor)
        drawRectangle(self, x + 1, y + 1, w - 2, h - 2, true)

    elseif self.isGlowing then
        setColor(self, highlightColor)
        drawRectangle(self, x + 1, y + 1, w - 2, h - 2, true)
    end
end

return Button