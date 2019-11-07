local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Widget = require("GUI.Widget")
local Toggle = require("GUI.Toggle")

local function Button(parameters, fromObject)
    local parameters = parameters or {}
    local instance = Widget(parameters, fromObject)

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

    function instance:isPressed() return _pressState:getState() end
    function instance:justPressed() return _pressState:justTurnedOn() end
    function instance:justReleased() return _pressState:justTurnedOff() end
    function instance:glow()
        _glowState = true
        instance:queueRedraw()
    end
    function instance:unGlow()
        _glowState = false
        instance:queueRedraw()
    end
    function instance:press()
        _pressState:setState(true)
        instance:queueRedraw()
    end
    function instance:release()
        _pressState:setState(false)
        instance:queueRedraw()
    end
    function instance:toggle()
        _pressState:toggle()
        instance:queueRedraw()
    end

    function instance:beginUpdate()
        _pressState:update()
    end
    function instance:update()
        local mouse = instance:getMouse()
        local mouseLeftButton = mouse:getButtons().left
        if _glowOnMouseOver then
            if mouse:justEntered(instance) then instance:glow() end
            if mouse:justLeft(instance) then instance:unGlow() end
        end
        if _pressOnClick then
            if mouseLeftButton:justPressed(instance) then instance:press() end
            if mouseLeftButton:justReleased(instance) then instance:release() end
        end
        if _toggleOnClick then
            if mouseLeftButton:justPressed(instance) then instance:toggle() end
        end
    end
    function instance:draw()
        local width = instance.width
        local height = instance.height

        -- Draw the main instance.
        instance:setColor(_color)
        instance:drawRectangle(0, 0, width, height, true)

        -- Draw a light outline around the instance.
        instance:setColor(_edgeColor)
        instance:drawRectangle(0, 0, width, height, false)

        -- Draw the instance's label.
        instance:setColor(_labelColor)
        instance:setFont(_labelFont, _labelFontSize)
        instance:drawString(_label, 0, 0, 5, width, height)

        if instance:isPressed() then
            instance:setColor(_pressedColor)
            instance:drawRectangle(0, 0, width, height, true)

        elseif _glowState then
            instance:setColor(_glowColor)
            instance:drawRectangle(0, 0, width, height, true)
        end
    end

    return instance
end

return Button