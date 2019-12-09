local GUI = require("GUI")
local Button = require("Button")

local DrawableButton = {}
setmetatable(DrawableButton, { __index = Button })

function DrawableButton:new()
    local self = self or {}
    Button.new(self)
    setmetatable(self, { __index = DrawableButton })
    self:setWidth(0)
    self:setHeight(0)
    self:setBodyColor{ 0.4, 0.4, 0.4, 1, 0 }
    self:setOutlineColor{ 0.15, 0.15, 0.15, 1, 0 }
    self:setPressedColor{ 1, 1, 1, -0.1, 1 }
    self:setHighlightColor{ 1, 1, 1, 0.1, 1 }
    return self
end

function DrawableButton:getWidth() return self._width end
function DrawableButton:setWidth(v) self._width = v end
function DrawableButton:getHeight() return self._height end
function DrawableButton:setHeight(v) self._height = v end
function DrawableButton:getBodyColor() return self._bodyColor end
function DrawableButton:setBodyColor(v) self._bodyColor = v end
function DrawableButton:getOutlineColor() return self._outlineColor end
function DrawableButton:setOutlineColor(v) self._outlineColor = v end
function DrawableButton:getHighlightColor() return self._highlightColor end
function DrawableButton:setHighlightColor(v) self._highlightColor = v end
function DrawableButton:getPressedColor() return self._pressedColor end
function DrawableButton:setPressedColor(v) self._pressedColor = v end

function DrawableButton:mouseIsInside()
    local x, y, w, h = self:getX(), self:getY(), self:getWidth(), self:getHeight()
    local mouseX, mouseY = GUI.mouseX, GUI.mouseY
    return mouseX >= x and mouseX <= x + w
        and mouseY >= y and mouseY <= y + h
end

function DrawableButton:draw(dt)
    local x, y, w, h = self:getX(), self:getY(), self:getWidth(), self:getHeight()
    local isPressed, mouseIsInside = self:isPressed(), self:mouseIsInside()
    local bodyColor, outlineColor, highlightColor, pressedColor = self:getBodyColor(), self:getOutlineColor(), self:getHighlightColor(), self:getPressedColor()

    -- Draw the body.
    GUI.setColor(bodyColor)
    GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, true)

    -- Draw a dark outline around.
    GUI.setColor(outlineColor)
    GUI.drawRectangle(x, y, w, h, false)

    -- Draw a light outline around.
    GUI.setColor(highlightColor)
    GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, false)

    if isPressed then
        GUI.setColor(pressedColor)
        GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, true)

    elseif mouseIsInside then
        GUI.setColor(highlightColor)
        GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, true)
    end
end

return DrawableButton