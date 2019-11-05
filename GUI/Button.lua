local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Toggle = require("GUI.Toggle")

local function Button(parameters)
    local self = {}

    local _gui = parameters.gui
    local _mouse = _gui.getMouse()
    local _mouseLeftButton = _mouse.getButtons().left
    local _x = parameters.x or 0
    local _y = parameters.y or 0
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
        --_gui.queueRedraw(self)
    end
    function self.unGlow()
        _glowState = false
        --_gui.queueRedraw(self)
    end
    function self.press()
        _pressState.setState(true)
        --_gui.queueRedraw(self)
    end
    function self.release()
        _pressState.setState(false)
        --_gui.queueRedraw(self)
    end
    function self.toggle()
        _pressState.toggle()
        --_gui.queueRedraw(self)
    end
    function self.handleDefaultMouseInteraction()
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
    function self.handleDefaultDrawing()
        -- Draw the main button.
        _gui.setColor(_color)
        _gui.drawRectangle(_x, _y, _width, _height, true)

        -- Draw a light outline around the button.
        _gui.setColor(_edgeColor)
        _gui.drawRectangle(_x, _y, _width, _height, false)

        -- Draw the button's label.
        _gui.setColor(_labelColor)
        _gui.setFont(_labelFont, _labelFontSize)
        _gui.drawString(_label, _x, _y, 5, _x + _width, _y + _height)

        if self.isPressed() then
            _gui.setColor(_pressedColor)
            _gui.drawRectangle(_x, _y, _width, _height, true)

        elseif _glowState then
            _gui.setColor(_glowColor)
            _gui.drawRectangle(_x, _y, _width, _height, true)
        end
    end
    function self.pointIsInside(x, y)
        return x >= _x and x <= _x + _width
           and y >= _y and y <= _y + _height
    end
    local _updateFunctions = {
        self.updateStates,
        self.handleDefaultMouseInteraction,
        self.handleDefaultDrawing
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