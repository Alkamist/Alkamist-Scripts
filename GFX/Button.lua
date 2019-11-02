package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ToggleState = require("GFX.ToggleState")
local GFXElement = require("GFX.GFXElement")

local Button = setmetatable({}, { __index = GFXElement })

function Button:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.label = init.label or ""
    self.labelFont = init.labelFont or "Arial"
    self.labelFontSize = init.labelFontSize or 14
    self.color = init.color or {0.3, 0.3, 0.3, 1.0, 0}
    self.edgeColor = init.edgeColor or {1.0, 1.0, 1.0, 0.1, 1}
    self.highlightColor = init.mouseOverColor or {1.0, 1.0, 1.0, 0.15, 1}
    self.downColor = init.downColor or {1.0, 1.0, 1.0, -0.15, 1}
    self.labelColor = init.labelColor or {1.0, 1.0, 1.0, 0.4, 1}

    self.state = ToggleState:new(false)

    return self
end

function Button:update()
    self.state:update()
end
function Button:press()
    self.state:set(true)
end
function Button:release()
    self.state:set(false)
end
function Button:toggle()
    self.state:toggle()
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
        self:setColor(self.downColor)
        self:drawRectangle(0, 0, self.w, self.h, true)

    elseif self:mouseIsInside() then
        self:setColor(self.highlightColor)
        self:drawRectangle(0, 0, self.w, self.h, true)
    end
end

return Button