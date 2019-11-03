package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Class = require("Class")
local ToggleState = require("GFX.ToggleState")

local Button = {
    x = 0,
    y = 0,
    w = 0,
    h = 0,
    label = "",
    labelFont = "Arial",
    labelFontSize = 14,
    color = { 0.3, 0.3, 0.3, 1.0, 0 },
    edgeColor = { 1.0, 1.0, 1.0, 0.1, 1 },
    glowColor = { 1.0, 1.0, 1.0, 0.15, 1 },
    pressedColor = { 1.0, 1.0, 1.0, -0.15, 1 },
    labelColor = { 1.0, 1.0, 1.0, 0.4, 1 },
    state = ToggleState.create{ current = false },
    glowState = false,
    glowOnMouseOver = true,
    pressOnClick = true,
    toggleOnClick = false
}
function Button:create(parameters)
    return Class.create({ Button }, parameters)
end

function Button:update()
    self.state:update()

    local mouse = self.mouse

    if self.glowOnMouseOver then
        if mouse:justEntered(self) then self:glow() end
        if mouse:justLeft(self) then self:unGlow() end
    end
    if self.pressOnClick then
        if mouse.buttons.left:justPressed(self) then self:press() end
        if mouse.buttons.left:justReleased(self) then self:release() end
    end
    if self.toggleOnClick then
        if mouse.buttons.left:justPressed(self) then self:toggle() end
    end
end
function Button:glow()
    self.glowState = true
    self:queueRedraw()
end
function Button:unGlow()
    self.glowState = false
    self:queueRedraw()
end
function Button:press()
    self.state:set(true)
    self:queueRedraw()
end
function Button:release()
    self.state:set(false)
    self:queueRedraw()
end
function Button:toggle()
    self.state:toggle()
    self:queueRedraw()
end
function Button:isPressed()
    return self.state.current
end
function Button:justPressed()
    return self.state:justTurnedOn()
end
function Button:justReleased()
    return self.state:justTurnedOff()
end
function Button:draw()
    -- Draw the main button.
    self:setColor(self.color)
    self:drawRectangle(0, 0, self.w, self.h, true)

    -- Draw a light outline around the button.
    self:setColor(self.edgeColor)
    self:drawRectangle(0, 0, self.w, self.h, false)

    -- Draw the button's label.
    self:setColor(self.labelColor)
    self:setFont(self.labelFont, self.labelFontSize)
    self:drawString(self.label, 0, 0, 5, self.w, self.h)

    if self:isPressed() then
        self:setColor(self.pressedColor)
        self:drawRectangle(0, 0, self.w, self.h, true)

    elseif self.glowState then
        self:setColor(self.glowColor)
        self:drawRectangle(0, 0, self.w, self.h, true)
    end
end

return Button