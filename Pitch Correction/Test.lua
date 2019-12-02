local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local Button = require("Button")
local MovingButton = require("MovingButton")

local previousLeftMouseButtonState = false
local previousMouseX = 0
local previousMouseY = 0

local button1 = Button.new{
    isPressed = GUI.leftMouseButtonIsPressed,
    wasPreviouslyPressed = function() return previousLeftMouseButtonState end,
    getX = GUI.getMouseX,
    getPreviousX = function() return previousMouseX end,
    getY = GUI.getMouseY,
    getPreviousY = function() return previousMouseY end
}

button1 = MovingButton.new(button1)

function GUI.update()
    if button1:justStartedDragging() then msg("left") end

    button1:update()

    previousLeftMouseButtonState = GUI.leftMouseButtonIsPressed()
    previousMouseX = GUI.getMouseX()
    previousMouseY = GUI.getMouseY()
end

GUI.run()