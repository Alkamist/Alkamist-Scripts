package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ToggleState = require("GFX.ToggleState")

local Button = {}

function Button:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.x = init.x or 0
    self.y = init.y or 0
    self.w = init.w or 0
    self.h = init.h or 0

    self.label = init.label or ""
    self.labelFont = init.labelFont or "Arial"
    self.labelFontSize = init.labelFontSize or 14
    self.color = init.color or {0.3, 0.3, 0.3, 1.0, 0}
    self.edgeColor = init.edgeColor or {1.0, 1.0, 1.0, 0.1, 1}
    self.glowColor = init.glowColor or {1.0, 1.0, 1.0, 0.15, 1}
    self.pressedColor = init.pressedColor or {1.0, 1.0, 1.0, -0.15, 1}
    self.labelColor = init.labelColor or {1.0, 1.0, 1.0, 0.4, 1}

    self.state = ToggleState:new(false)
    self.glowState = false

    if init.glowOnMouseOver ~= nil then self.glowOnMouseOver = init.glowOnMouseOver else self.glowOnMouseOver = true end
    if init.pressOnClick ~= nil then self.pressOnClick = init.pressOnClick else self.pressOnClick = true end
    if init.toggleOnClick ~= nil then
        self.toggleOnClick = init.toggleOnClick
    else
        self.toggleOnClick = false
    end
    if self.toggleOnClick then self.pressOnClick = false end

    return self
end

function Button:update()
    self.state:update()

    local mouse = self.mouse

    if self.glowOnMouseOver then
        if mouse:justEntered(self) then self:glow() end
        if mouse:justLeft(self) then self:unGlow() end
    end
    if self.pressOnClick then
        if mouse:didInside(self, mouse.left:justPressed()) then self:press() end
        if mouse:didInside(self, mouse.left:justReleased()) then self:release() end
    end
    if self.toggleOnClick then
        if mouse:didInside(self, mouse.left:justPressed()) then self:toggle() end
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
    return self.state.justTurnedOn
end
function Button:justReleased()
    return self.state.justTurnedOff
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