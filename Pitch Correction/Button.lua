local reaper = reaper
local gfx = gfx
local pairs = pairs

local Proxy = require("Proxy")
local Fn = require("Fn")
local Widget = require("Widget")
local GUI = require("GUI")
local mouse = GUI.mouse
local buttons = mouse.buttons
local leftMouseButton = buttons.left
local keyboard = GUI.keyboard
local modifiers = keyboard.modifiers
local keys = keyboard.keys
local window = GUI.window
local widgets = window.widgets

local Button = {}
function Button:new()
    local defaults = {
        color = { 0.3, 0.3, 0.3 },
        isPressed = false,
        wasPreviouslyPressed = false,
        isGlowing = false,
        glowWhenMouseIsOver = true,
        pressControl = leftMouseButton,
        toggleControl = nil,
        label = "",
        labelFont = "Arial",
        labelFontSize = 14
    }

    Widget.new(self)

    self:setProperty("justPressed", { get = function(self) return self.isPressed and not self.wasPreviouslyPressed end })
    self:setProperty("justReleased", { get = function(self) return not self.isPressed and self.wasPreviouslyPressed end })

    Fn.initialize(self, defaults)
    Fn.initialize(self, Button)
    return self
end

function Button:update()
    if self.glowWhenMouseIsOver then
        self.isGlowing = mouse:isInsideWidget(self)
    end
    if self.pressControl then
        if self.pressControl.justPressed and mouse:isInsideWidget(self) then self.isPressed = true end
        if self.pressControl.justReleased then self.isPressed = false end
    end
    if self.toggleControl then
        if self.toggleControl.justPressed and mouse:isInsideWidget(self) then self.isPressed = not self.isPressed end
    end
end
function Button:draw()
    local x, y, w, h = self.x, self.y, self.width, self.height
    local text = self.label
    local font = self.labelFont
    local fontSize = self.labelFontSize
    local isPressed = self.isPressed
    local isGlowing = self.isGlowing

    gfx.x = x
    gfx.y = y

    -- Draw the body.
    Fn.setColor(self.color)
    gfx.rect(x, y, w, h, true)

    -- Draw a dark outline around.
    gfx.set(0.15, 0.15, 0.15, gfx.a, gfx.mode)
    gfx.rect(x, y, w, h, false)

    -- Draw a light outline around.
    gfx.set(1, 1, 1, 0.1, 1)
    gfx.rect(x + 1, y + 1, w - 2, h - 2, false)

    -- Draw the label.
    gfx.set(1, 1, 1, 0.4, 1)
    gfx.setfont(1, font, fontSize)
    gfx.drawstr(text, 5, x + w, y + h)

    if isPressed then
        gfx.set(1, 1, 1, -0.15, 1)
        gfx.rect(x + 1, y + 1, w - 2, h - 2, true)

    elseif isGlowing then
        gfx.set(1, 1, 1, 0.15, 1)
        gfx.rect(x + 1, y + 1, w - 2, h - 2, true)
    end
end
function Button:endUpdate()
    self.wasPreviouslyPressed = self.isPressed
end

return Button