local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Drawable = require("GUI.Drawable")
local Toggle = require("GUI.Toggle")

local function Button(parameters)
    local self = {}

    local _draw = Drawable(parameters)
    local _mouse = parameters.mouse
    local _mouseLeftButton = _mouse.getButtons().left
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

    function self.isPressed() return _pressState.getState() end
    function self.justPressed() return _pressState.justTurnedOn() end
    function self.justReleased() return _pressState.justTurnedOff() end
    function self.pointIsInside(pointX, pointY) return _draw.pointIsInsideDrawableBounds(pointX, pointY) end
    function self.glow()
        _glowState = true
        _draw.queueRedraw()
    end
    function self.unGlow()
        _glowState = false
        _draw.queueRedraw()
    end
    function self.press()
        _pressState.setState(true)
        _draw.queueRedraw()
    end
    function self.release()
        _pressState.setState(false)
        _draw.queueRedraw()
    end
    function self.toggle()
        _pressState.toggle()
        _draw.queueRedraw()
    end
    function self.updateStates()
        _pressState.update()
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

    function self.doDrawFunction() _draw.doDrawFunction() end
    function self.blitToMainWindow() _draw.blitToMainWindow() end
    _draw.setDrawFunction(function()
        local width = _draw.getWidth()
        local height = _draw.getHeight()

        -- Draw the main button.
        _draw.setColor(_color)
        _draw.drawRectangle(0, 0, width, height, true)

        -- Draw a light outline around the button.
        _draw.setColor(_edgeColor)
        _draw.drawRectangle(0, 0, width, height, false)

        -- Draw the button's label.
        _draw.setColor(_labelColor)
        _draw.setFont(_labelFont, _labelFontSize)
        _draw.drawString(_label, 0, 0, 5, width, height)

        if self.isPressed() then
            _draw.setColor(_pressedColor)
            _draw.drawRectangle(0, 0, width, height, true)

        elseif _glowState then
            _draw.setColor(_glowColor)
            _draw.drawRectangle(0, 0, width, height, true)
        end
    end)

    local _updateFunctions = {
        self.updateStates,
        self.interactWithMouse
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