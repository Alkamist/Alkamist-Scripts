local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")
local MouseButtons = require("MouseButtons")
local DrawableButton = require("DrawableButton")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local buttons = {}
local x = 0
local y = 0
local size = 80
local numberOfButtons = 100
for i = 1, numberOfButtons do
    buttons[i] = DrawableButton()
    buttons[i].setX(x)
    buttons[i].setY(y)
    buttons[i].setWidth(size)
    buttons[i].setHeight(size)

    x = x + size
    if x >= 1000 - size then
        x = 0
        y = y + size
    end
end

MouseButtons.left.setObjectsToDrag(buttons)

function GUI.update(dt)
    MouseButtons.updateState(dt)

    for i = 1, numberOfButtons do
        local button = buttons[i]

        button.setX(button.getX() + 2 - math.random() * 4)
        button.setY(button.getY() + 2 - math.random() * 4)
        button.setIsPressed(MouseButtons.left.wasPressedInsideObject(button))

        if MouseButtons.left.justDraggedObject(button) then
            button.setX(button.getX() + MouseButtons.left.getXChange())
            button.setY(button.getY() + MouseButtons.left.getYChange())
        end

        button.draw()
        button.updatePreviousState(dt)
    end

    MouseButtons.updatePreviousState(dt)
end

GUI.run()