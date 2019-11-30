local reaper = reaper
function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end
package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
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

local Button = require("Button")
local Drawable = require("Drawable")
local DrawableButton = require("DrawableButton")

window:initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
window:setBackgroundColor(0.2, 0.2, 0.2)

local numberOfButtons = 200
local x = 0
local y = 0
local buttonSize = 20
local buttons = {}
for i = 1, numberOfButtons do
    buttons[i] = DrawableButton.new{
        x = { x },
        y = { y },
        width = { buttonSize },
        height = { buttonSize },
        button = Button.new{ pressState = { false, false } },

        drawable = Drawable.new{
            x = { x },
            y = { y },
            alpha = { 1 },
            blendMode = { 0 },
        },

        colors = {
            body = { 0.4, 0.4, 0.4 },
            outline = { 0.15, 0.15, 0.15 },
            highlight = { 1, 1, 1, 0.1, 1 },
            pressed = { 1, 1, 1, -0.15, 1 }
        }
    }

    x = x + buttonSize
    if x > 1000 - buttonSize then
        x = 0
        y = y + buttonSize
    end
end

--local button1 = DrawableButton.new{
--    x = { 50 },
--    y = { 50 },
--    width = { 100 },
--    height = { 40 },
--    button = Button.new{ pressState = { false, false } },
--
--    drawable = Drawable.new{
--        x = { 50 },
--        y = { 50 },
--        alpha = { 1 },
--        blendMode = { 0 },
--    },
--
--    colors = {
--        body = { 0.5, 0.5, 0.5 },
--        outline = { 0.15, 0.15, 0.15 },
--        highlight = { 1, 1, 1, 0.07, 1 },
--        pressed = { 1, 1, 1, -0.15, 1 }
--    }
--}

function GUI.update()
    for i = 1, numberOfButtons do
        local button = buttons[i]
        button.button.pressState[1] = math.random() > 0.5
        button:draw()
    end
end

GUI.run()