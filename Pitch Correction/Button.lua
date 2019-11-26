local reaper = reaper
local gfx = gfx
local pairs = pairs

local Fn = require("Fn")
local GUI = require("GUI")
local mouse = GUI.mouse
local Widget = require("Widget")

local Button = {}
function Button.new(self)
    local states = {}

    states.color = { 0.3, 0.3, 0.3 }

    states.isPressed = false
    states.wasPreviouslyPressed = false
    states.justPressed = false
    states.justReleased = false
    states.isGlowing = false
    states.glowWhenMouseIsOver = true
    states.pressControl = mouse.buttons.left
    states.toggleControl = nil

    states.label = ""
    states.labelFont = "Arial"
    states.labelFontSize = 14

    return Widget.new(Fn.initialize(self, states))
end

function Button.update(self)
    Widget.update(self, function()
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
    end)
end
function Button.draw(self)
    Widget.draw(self, function()
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
    end)
end
function Button.endUpdate(self)
    Widget.endUpdate(self, function()
        self.wasPreviouslyPressed = self.isPressed
    end)
end

return Button