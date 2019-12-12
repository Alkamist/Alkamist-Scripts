local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local Button = require("Button")
local BoxSelect = require("BoxSelect")

local buttons = {}
local x = 0
local y = 0
local size = 15
local numberOfButtons = 3000
for i = 1, numberOfButtons do
    local button = Button.new{
        x = x,
        y = y,
        width = size,
        height = size
    }
    buttons[i] = button

    x = x + size
    if x >= 1000 - size then
        x = 0
        y = y + size
    end
end

local boxSelect = BoxSelect.new{
    objectsToSelect = buttons
}

function GUI.update(dt)
    BoxSelect.update(boxSelect, dt)
    for i = 1, numberOfButtons do
        local button = buttons[i]

        button.x = button.x + 2 - math.random() * 4
        button.y = button.y + 2 - math.random() * 4

        if GUI.leftMouseButton.justDraggedObject[button] and button.isSelected then
            button.x = button.x + GUI.mouseXChange
            button.y = button.y + GUI.mouseYChange
        end

        Button.update(button, dt)
        button.isPressed = button.isSelected
        Button.draw(button, dt)
    end
    BoxSelect.draw(boxSelect, dt)
end

GUI.run()