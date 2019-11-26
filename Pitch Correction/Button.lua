local reaper = reaper
local gfx = gfx
local pairs = pairs

local Fn = require("Fn")
local GUI = require("GUI")
local mouse = GUI.mouse
local Widget = require("Widget")

local Button = {}
function Button.new(init)
    local self = Widget.new(init)

    self.color = Fn.makeGetSet(init.color, { 0.3, 0.3, 0.3 })
    self.isPressed = Fn.makeGetSet(init.isPressed, false)
    self.wasPreviouslyPressed = Fn.makeGetSet(init.isPressed, false)
    self.isGlowing = Fn.makeGetSet(init.isGlowing, false)
    self.glowWhenMouseIsOver = Fn.makeGetSet(init.glowWhenMouseIsOver, true)
    self.pressControl = Fn.makeGetSet(init.pressControl, mouse.buttons.left)
    self.toggleControl = Fn.makeGetSet(init.toggleControl)
    self.label = Fn.makeGetSet(init.label, "")
    self.labelFont = Fn.makeGetSet(init.labelFont, "Arial")
    self.labelFontSize = Fn.makeGetSet(init.labelFontSize, 14)

    function self:justPressed() return self:isPressed() and not self:wasPreviouslyPressed() end
    function self:justReleased() return not self:isPressed() and self:wasPreviouslyPressed() end

    local widgetUpdate = self.update
    function self:update()
        widgetUpdate(self, function()
            local pressControl = self:pressControl()
            local toggleControl = self:toggleControl()
            local mouseIsInside = self:mouseIsInside()
            if self:glowWhenMouseIsOver() then
                if self:mouseJustEntered() then self:isGlowing(true) end
                if self:mouseJustLeft() then self:isGlowing(false) end
            end
            if pressControl then
                if pressControl.justPressed and mouseIsInside then self:isPressed(true) end
                if pressControl.justReleased then self:isPressed(false) end
            end
            if toggleControl then
                if toggleControl.justPressed and mouseIsInside then self:isPressed(not self:isPressed()) end
            end
        end)
    end
    local widgetDraw = self.draw
    function self:draw()
        widgetDraw(self, function()
            local x, y, w, h = self:x(), self:y(), self:width(), self:height()
            local text = self:label()
            local font = self:labelFont()
            local fontSize = self:labelFontSize()
            local isPressed = self:isPressed()
            local isGlowing = self:isGlowing()

            gfx.x = x
            gfx.y = y

            -- Draw the body.
            Fn.setColor(self:color())
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
    local widgetEndUpdate = self.endUpdate
    function self:endUpdate()
        widgetEndUpdate(self, function()
            self:wasPreviouslyPressed(self:isPressed())
        end)
    end

    return self
end

return Button