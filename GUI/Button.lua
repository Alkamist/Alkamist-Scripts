local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Drawable = require("GUI.Drawable")
local Toggle = require("GUI.Toggle")

local function Button(parameters)
    local self = Drawable(parameters)

    local _mouse = parameters.mouse
    local _mouseLeftButton = _mouse.getButtons().left
    local _width = parameters.width or 0
    local _height = parameters.height or 0
    local _label = parameters.label or ""
    local _labelFont = parameters.labelFont or "Arial"
    local _labelFontSize = parameters.labelFontSize or 14
    local _labelColor = parameters.labelColor or { 1.0, 1.0, 1.0, 0.4, 1 }
    local _color = parameters.color or { 0.3, 0.3, 0.3, 1.0, 0 }
    local _edgeColor = parameters.edgeColor or { 1.0, 1.0, 1.0, 0.1, 1 }
    local _glowColor = parameters.glowColor or { 1.0, 1.0, 1.0, 0.15, 1 }
    local _pressedColor = parameters.pressedColor or { 1.0, 1.0, 1.0, -0.15, 1 }
    local _pressState = Toggle(false)
    local _glowState = false

    local _glowOnMouseOver = parameters.glowOnMouseOver
    if _glowOnMouseOver == nil then _glowOnMouseOver = true end

    local _pressOnClick = parameters.pressOnClick
    if _pressOnClick == nil then _pressOnClick = true end

    local _toggleOnClick = parameters.toggleOnClick
    if _toggleOnClick == nil then _toggleOnClick = false end
    if _toggleOnClick == true then _pressOnClick = false end

    function self.isPressed()
        return _pressState.getState()
    end
    function self.justPressed()
        return _pressState.justTurnedOn()
    end
    function self.justReleased()
        return _pressState.justTurnedOff()
    end
    function self.updateStates()
        _pressState.update()
    end
    function self.glow()
        _glowState = true
        self.queueRedraw()
    end
    function self.unGlow()
        _glowState = false
        self.queueRedraw()
    end
    function self.press()
        _pressState.setState(true)
        self.queueRedraw()
    end
    function self.release()
        _pressState.setState(false)
        self.queueRedraw()
    end
    function self.toggle()
        _pressState.toggle()
        self.queueRedraw()
    end
    function self.interactWithMouse()
        if _glowOnMouseOver then
            if _mouse.justEntered(self) then self.glow() end
            if _mouse.justLeft(self) then self.unGlow() end
        end
        if _pressOnClick then
            if _mouseLeftButton.justPressed(self) then self.press() end
            if _mouseLeftButton.justReleased(self) then self.release() end
        end
        if _toggleOnClick then
            if _mouseLeftButton.justPressed(self) then self.toggle() end
        end
    end
    function self.draw()
        -- Draw the main button.
        self.setColor(_color)
        self.drawRectangle(0, 0, _width, _height, true)

        -- Draw a light outline around the button.
        self.setColor(_edgeColor)
        self.drawRectangle(0, 0, _width, _height, false)

        -- Draw the button's label.
        self.setColor(_labelColor)
        self.setFont(_labelFont, _labelFontSize)
        self.drawString(_label, 0, 0, 5, _width, _height)

        if self.isPressed() then
            self.setColor(_pressedColor)
            self.drawRectangle(0, 0, _width, _height, true)

        elseif _glowState then
            self.setColor(_glowColor)
            self.drawRectangle(0, 0, _width, _height, true)
        end
    end
    function self.pointIsInside(pointX, pointY)
        local x = self.getX()
        local y = self.getY()
        return pointX >= x and pointX <= x + _width
           and pointY >= y and pointY <= y + _height
    end

    local _updateFunctions = {
        self.updateStates,
        self.interactWithMouse,
        self.draw
    }
    function self.getUpdateFunction(update)
        return _updateFunctions[update]
    end
    function self.setUpdateFunction(update, fn)
        _updateFunctions[update] = fn
    end

    return self
end

return Button