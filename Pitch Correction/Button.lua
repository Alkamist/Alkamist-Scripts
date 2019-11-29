local GUI = require("GUI")
local mouse = GUI.mouse
local mouseButtons = mouse.buttons
local leftMouseButton = mouseButtons.left
local middleMouseButton = mouseButtons.middle
local rightMouseButton = mouseButtons.right
local keyboard = GUI.keyboard
local keyboardModifiers = keyboard.modifiers
local shiftKey = keyboardModifiers.shift
local controlKey = keyboardModifiers.control
local windowsKey = keyboardModifiers.windows
local altKey = keyboardModifiers.alt
local keyboardKeys = GUI.keyboard.keys
local window = GUI.window

local pairs = pairs
local type = type

local Fn = require("Fn")
local initialize = Fn.initialize

local Widget = require("Widget")

local setColor = gfx.set
local drawRectangle = gfx.rect
local drawString = gfx.drawstr
local setFont = gfx.setfont

local Button = {}
function Button:new()
    local defaults = {
        label = "",
        labelFont = "Arial",
        labelFontSize = 14,
        isPressed = false,
        wasPreviouslyPressed = false,
        justPressed = false,
        justReleased = false,
        isGlowing = false,
        color = { 0.3, 0.3, 0.3 },
        pressControl = leftMouseButton,
        toggleControl = nil,
        glowWhenMouseIsInside = true
    }

    initialize(self, defaults)
    initialize(self, Button)
    return Widget.new(self)
end

function Button:update()
    Widget.update(self)

    if self.glowWhenMouseIsInside then self.isGlowing = self.mouseIsInside end
    if self.pressControl then
        if self.pressControl.justPressed and self.mouseIsInside then self.isPressed = true end
        if self.pressControl.justReleased then self.isPressed = false end
    end

    self.justPressed = self.isPressed and not self.wasPreviouslyPressed
    self.justReleased = not self.isPressed and self.wasPreviouslyPressed
end
function Button:draw()
    local a, mode = gfx.a, gfx.mode

    local x, y, w, h = self.x, self.y, self.width, self.height
    local text, font, fontSize = self.label, self.labelFont, self.labelFontSize
    local isPressed, isGlowing = self.isPressed, self.isGlowing
    local color = self.color

    gfx.x = x
    gfx.y = y

    -- Draw the body.
    setColor(color[1], color[2], color[3], gfx.a, gfx.mode)
    drawRectangle(x, y, w, h, true)

    -- Draw a dark outline around.
    setColor(0.15, 0.15, 0.15, gfx.a, gfx.mode)
    drawRectangle(x, y, w, h, false)

    -- Draw a light outline around.
    setColor(1, 1, 1, 0.1, 1)
    drawRectangle(x + 1, y + 1, w - 2, h - 2, false)

    -- Draw the label.
    setColor(1, 1, 1, 0.4, 1)
    setFont(1, font, fontSize)
    drawString(text, 5, x + w, y + h)

    if isPressed then
        setColor(1, 1, 1, -0.15, 1)
        drawRectangle(x + 1, y + 1, w - 2, h - 2, true)

    elseif isGlowing then
        setColor(1, 1, 1, 0.15, 1)
        drawRectangle(x + 1, y + 1, w - 2, h - 2, true)
    end

    gfx.a, gfx.mode = a, mode
end
function Button:endUpdate()
    self.wasPreviouslyPressed = self.isPressed
end

return Button