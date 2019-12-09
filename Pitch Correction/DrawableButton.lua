local GUI = require("GUI")
local MouseButtons = require("MouseButtons")
local Button = require("Button")

return function(self)
    local self = self or {}
    if self.DrawableButton then return self end
    self.DrawableButton = true
    Button(self)
    local _buttonUpdateState = self.updateState

    local _width, _height
    local _bodyColor
    local _outlineColor
    local _highlightColor
    local _pressedColor
    local _shouldToggle

    function self.getWidth() return _width end
    function self.setWidth(v) _width = v end
    function self.getHeight() return _height end
    function self.setHeight(v) _height = v end
    function self.getBodyColor() return _bodyColor end
    function self.setBodyColor(v) _bodyColor = v end
    function self.getOutlineColor() return _outlineColor end
    function self.setOutlineColor(v) _outlineColor = v end
    function self.getHighlightColor() return _highlightColor end
    function self.setHighlightColor(v) _highlightColor = v end
    function self.getPressedColor() return _pressedColor end
    function self.setPressedColor(v) _pressedColor = v end
    function self.shouldToggle() return _shouldToggle end
    function self.setShouldToggle(v) _shouldToggle = v end

    function self.mouseIsInside()
        local x, y, w, h = self.getX(), self.getY(), self.getWidth(), self.getHeight()
        local mouseX, mouseY = GUI.mouseX, GUI.mouseY
        return mouseX >= x and mouseX <= x + w
            and mouseY >= y and mouseY <= y + h
    end

    function self.updateState(dt)
        _buttonUpdateState(dt)

        if MouseButtons.left.justPressedObject(self) then
            if self.shouldToggle() then
                self.setIsPressed(not self.isPressed())
            else
                self.setIsPressed(true)
            end
        end
        if MouseButtons.left.justReleasedObject(self) then
            if not self.shouldToggle() then
                self.setIsPressed(false)
            end
        end
    end
    function self.draw(dt)
        local x, y, w, h = self.getX(), self.getY(), self.getWidth(), self.getHeight()
        local isPressed, mouseIsInside = self.isPressed(), self.mouseIsInside()
        local bodyColor, outlineColor, highlightColor, pressedColor = self.getBodyColor(), self.getOutlineColor(), self.getHighlightColor(), self.getPressedColor()

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

    self.setWidth(0)
    self.setHeight(0)
    self.setBodyColor{ 0.4, 0.4, 0.4, 1, 0 }
    self.setOutlineColor{ 0.15, 0.15, 0.15, 1, 0 }
    self.setPressedColor{ 1, 1, 1, -0.1, 1 }
    self.setHighlightColor{ 1, 1, 1, 0.1, 1 }
    self.setShouldToggle(false)

    MouseButtons.left.trackObject(self)

    return self
end