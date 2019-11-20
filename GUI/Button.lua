local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Widget = require("GUI.Widget")

local Button = {}
function Button:new(parameters)
    local parameters = parameters or {}
    local self = Widget:new(parameters)

    if parameters.pressOnClick == nil then parameters.pressOnClick = true end
    if parameters.glowOnMouseOver == nil then parameters.glowOnMouseOver = true end

    self:setLabel(parameters.label or "")
    self:setLabelFont(parameters.labelFont or "Arial")
    self:setLabelFontSize(parameters.labelFontSize or 14)
    self:setLabelColor(parameters.labelColor or { 1.0, 1.0, 1.0, 0.4, 1 })
    self:setColor(parameters.color or { 0.3, 0.3, 0.3, 1.0, 0 })
    self:setOutlineColor(parameters.outlineColor or { 0.15, 0.15, 0.15, 1.0, 0 })
    self:setEdgeColor(parameters.edgeColor or { 1.0, 1.0, 1.0, 0.1, 1 })
    self:setPressedColor(parameters.pressedColor or { 1.0, 1.0, 1.0, -0.15, 1 })
    self:setGlowColor(parameters.glowColor or { 1.0, 1.0, 1.0, 0.15, 1 })
    self:setGlowsOnMouseOver(parameters.glowOnMouseOver)
    self:setToggleOnClick(parameters.toggleOnClick)
    self:setPressOnClick(parameters.pressOnClick)

    self._pressState = parameters.isPressed
    self._previousPressState = parameters.isPressed

    return self
end

function Button:glowsOnMouseOver() return self._glowsOnMouseOver end
function Button:setGlowsOnMouseOver(value) self._glowsOnMouseOver = value end
function Button:getColor() return self._color end
function Button:setColor(value) self._color = value end
function Button:getOutlineColor() return self._outlineColor end
function Button:setOutlineColor(value) self._outlineColor = value end
function Button:getEdgeColor() return self._edgeColor end
function Button:setEdgeColor(value) self._edgeColor = value end
function Button:getLabel() return self._label end
function Button:setLabel(value) self._label = value end
function Button:getLabelColor() return self._labelColor end
function Button:setLabelColor(value) self._labelColor = value end
function Button:getLabelFont() return self._labelFont end
function Button:setLabelFont(value) self._labelFont = value end
function Button:getLabelFontSize() return self._labelFontSize end
function Button:setLabelFontSize(value) self._labelFontSize = value end
function Button:getPressedColor() return self._pressedColor end
function Button:setPressedColor(value) self._pressedColor = value end
function Button:getGlowColor() return self._glowColor end
function Button:setGlowColor(value) self._pressedColor = value end
function Button:getPressOnClick() return self._pressOnClick end
function Button:setPressOnClick(value)
    self._pressOnClick = value
    if value then self._toggleOnClick = false end
end
function Button:getToggleOnClick() return self._toggleOnClick end
function Button:setToggleOnClick(value)
    self._toggleOnClick = value
    if value then self._pressOnClick = false end
end

function Button:press()
    self._pressState = true
    self:queueRedraw()
end
function Button:release()
    self._pressState = false
    self:queueRedraw()
end
function Button:toggle()
    self._pressState = not self._pressState
    self:queueRedraw()
end
function Button:isPressed()
    return self._pressState
end
function Button:justPressed()
    return self._pressState and not self._previousPressState
end
function Button:justReleased()
    return not self._pressState and self._previousPressState
end
function Button:glow()
    self._glowState = true
    self:queueRedraw()
end
function Button:unGlow()
    self._glowState = false
    self:queueRedraw()
end
function Button:toggleGlow()
    self._glowState = not self._glowState
    self:queueRedraw()
end
function Button:isGlowing()
    return self._glowState
end

function Button:beginUpdate()
    self._previousPressState = self._pressState
end
function Button:update()
    local mouse = self:getMouse()
    local mouseLeftButton = mouse:getLeftButton()

    if self:glowsOnMouseOver() then
        if mouse:justEnteredWidget(self) then self:glow() end
        if mouse:justLeftWidget(self) then self:unGlow() end
    end
    if self:getPressOnClick() then
        if mouseLeftButton:justPressedWidget(self) then self:press() end
        if mouseLeftButton:justReleasedWidget(self) then self:release() end
    end
    if self:getToggleOnClick() then
        if mouseLeftButton:justPressedWidget(self) then self:toggle() end
    end
end
function Button:draw()
    local width =  self:getWidth()
    local height = self:getHeight()
    local color = self:getColor()
    local outlineColor = self:getOutlineColor()
    local edgeColor = self:getEdgeColor()
    local labelColor = self:getLabelColor()
    local labelFont = self:getLabelFont()
    local labelFontSize = self:getLabelFontSize()
    local pressedColor = self:getPressedColor()
    local glowColor = self:getGlowColor()

    -- Draw the body.
    self:setColor(color)
    self:drawRectangle(0, 0, width, height, true)

    -- Draw a dark outline around.
    self:setColor(outlineColor)
    self:drawRectangle(0, 0, width, height, false)

    -- Draw a light outline around.
    self:setColor(edgeColor)
    self:drawRectangle(1, 1, width - 2, height - 2, false)

    -- Draw the label.
    self:setColor(labelColor)
    self:setFont(labelFont, labelFontSize)
    self:drawString(_label, 0, 0, 5, width, height)

    if self:isPressed() then
        self:setColor(pressedColor)
        self:drawRectangle(1, 1, width - 2, height - 2, true)

    elseif self:isGlowing() then
        self:setColor(glowColor)
        self:drawRectangle(1, 1, width - 2, height - 2, true)
    end
end

return Button