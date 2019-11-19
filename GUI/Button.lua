local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Widget = require("GUI.Widget")
local Toggle = require("GUI.Toggle")

local Button = {}
function Button:new(parameters)
    local parameters = parameters or {}
    local self = Widget:new(parameters)

    local _label = parameters.label or ""
    local _labelFont = parameters.labelFont or "Arial"
    local _labelFontSize = parameters.labelFontSize or 14
    local _labelColor = parameters.labelColor or { 1.0, 1.0, 1.0, 0.4, 1 }
    local _color = parameters.color or { 0.3, 0.3, 0.3, 1.0, 0 }
    local _outlineColor = parameters.outlineColor or { 0.15, 0.15, 0.15, 1.0, 0 }
    local _edgeColor = parameters.edgeColor or { 1.0, 1.0, 1.0, 0.1, 1 }
    local _glowColor = parameters.glowColor or { 1.0, 1.0, 1.0, 0.15, 1 }
    local _pressedColor = parameters.pressedColor or { 1.0, 1.0, 1.0, -0.15, 1 }
    local _glowOnMouseOver = true
    local _toggleOnClick = false
    local _pressOnClick = true
    local _pressState = Toggle:new()
    local _glowState = false

    function self:setPressOnClick(value)
        _pressOnClick = value
        if value then _toggleOnClick = false end
    end
    function self:setToggleOnClick(value)
        _toggleOnClick = value
        if value then _pressOnClick = false end
    end
    function self:press()
        _pressState:setState(true)
        self:queueRedraw()
    end
    function self:release()
        _pressState:setState(false)
        self:queueRedraw()
    end
    function self:toggle()
        _pressState:toggle()
        self:queueRedraw()
    end
    function self:isPressed() return _pressState:getState() end
    function self:justPressed() return _pressState:justTurnedOn() end
    function self:justReleased() return _pressState:justTurnedOff() end
    function self:glow()
        _glowState = true
        self:queueRedraw()
    end
    function self:unGlow()
        _glowState = false
        self:queueRedraw()
    end
    function self:toggleGlow()
        _glowState = not _glowState
        self:queueRedraw()
    end

    function self:beginUpdate()
        _pressState:update()
    end
    function self:update()
        local mouse = self:getMouse()
        local mouseLeftButton = mouse:getLeftButton()

        if _glowOnMouseOver then
            if mouse:justEnteredWidget(self) then self:glow() end
            if mouse:justLeftWidget(self) then self:unGlow() end
        end
        if _pressOnClick then
            if mouseLeftButton:justPressedWidget(self) then self:press() end
            if mouseLeftButton:justReleasedWidget(self) then self:release() end
        end
        if _toggleOnClick then
            if mouseLeftButton:justPressedWidget(self) then self:toggle() end
        end
    end
    function self:draw()
        local width =  self:getWidth()
        local height = self:getHeight()

        -- Draw the body.
        self:setColor(_color)
        self:drawRectangle(0, 0, width, height, true)

        -- Draw a dark outline around.
        self:setColor(_outlineColor)
        self:drawRectangle(0, 0, width, height, false)

        -- Draw a light outline around.
        self:setColor(_edgeColor)
        self:drawRectangle(1, 1, width - 2, height - 2, false)

        -- Draw the label.
        self:setColor(_labelColor)
        self:setFont(_labelFont, _labelFontSize)
        self:drawString(_label, 0, 0, 5, width, height)

        if self:isPressed() then
            self:setColor(_pressedColor)
            self:drawRectangle(1, 1, width - 2, height - 2, true)

        elseif _glowState then
            self:setColor(_glowColor)
            self:drawRectangle(1, 1, width - 2, height - 2, true)
        end
    end

    if parameters.glowOnMouseOver then _glowOnMouseOver = true end
    if parameters.toggleOnClick then self:setToggleOnClick(true) end
    if parameters.pressOnClick then self:setPressOnClick(true) end
    return self
end

return Button