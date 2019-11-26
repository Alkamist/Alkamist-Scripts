local reaper = reaper
local gfx = gfx
local pairs = pairs

local Fn = require("Fn")
local GUI = require("GUI")
local mouse = GUI.mouse
local Widget = require("Widget")

local Button = {}
function Button.new(object)
    local self = {}

    self.color = { 0.3, 0.3, 0.3 }
    self.alpha = 1.0
    self.blendMode = 0

    self.isPressed = false
    self.wasPreviouslyPressed = false
    self.justPressed = false
    self.justReleased = false
    self.isGlowing = false
    self.glowWhenMouseIsOver = true
    self.pressControl = mouse.buttons.left
    self.toggleControl = nil

    self.label = ""
    self.labelFont = "Arial"
    self.labelFontSize = 14

    return Widget.new(Fn.makeNew(self, Button, object))
end

function Button:update()
    Widget.update(self)

    if self.glowWhenMouseIsOver then
        if self.mouseJustEntered then self.isGlowing = true end
        if self.mouseJustLeft then self.isGlowing = false end
    end
    if self.pressControl then
        if self.pressControl.justPressed and self.mouseIsInside then self.isPressed = true end
        if self.pressControl.justReleased then self.isPressed = false end
    end
    if self.toggleControl then
        if self.toggleControl.justPressed and self.mouseIsInside then self.isPressed = not self.isPressed end
    end

    self.justPressed = self.isPressed and not self.wasPreviouslyPressed
    self.justReleased = not self.isPressed and self.wasPreviouslyPressed
end
function Button:draw()
    local a, mode = gfx.a, gfx.mode
    local alpha, blendMode = self.alpha, self.blendMode
    local x, y, w, h = self.x, self.y, self.width, self.height
    local color = self.color
    local r, g, b = color[1], color[2], color[3]
    local text = self.label
    local font = self.labelFont
    local fontSize = self.labelFontSize
    local isPressed = self.isPressed
    local isGlowing = self.isGlowing

    gfx.x = x
    gfx.y = y

    -- Draw the body.
    gfx.set(r, g, b, alpha, blendMode)
    gfx.rect(x, y, w, h, true)

    -- Draw a dark outline around.
    gfx.set(0.15, 0.15, 0.15, alpha, 0)
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

    gfx.a, gfx.mode = a, mode
end
function Button:endUpdate()
    Widget.endUpdate(self)
    self.wasPreviouslyPressed = self.isPressed
end

return Button