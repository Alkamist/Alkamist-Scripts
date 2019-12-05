local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI:initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI:setBackgroundColor(0.2, 0.2, 0.2)

local MouseButtons = require("MouseButtons")
local Button = require("Button")
local BoxSelect = require("BoxSelect")

local button1 = Button:new{
    x = 100,
    y = 100,
    width = 100,
    height = 40,
    pressControl = MouseButtons.left,
    toggleControl = MouseButtons.right
}

local boxSelect = BoxSelect:new{
    selectionControl = MouseButtons.right,
    additiveControl = MouseButtons.shift,
    inversionControl = MouseButtons.control,
    objectsToSelect = { button1 }
}

MouseButtons.left.objectsToDrag = { button1 }

local x = MouseButtons.left.x
local previousX = MouseButtons.left.x
function GUI.update()
    for k, v in pairs(MouseButtons) do v:update() end

    previousX = x
    x = MouseButtons.left.x
    if MouseButtons.left.justDraggedObject[button1] then
        button1.x = button1.x + x - previousX
    end

    button1:update()
    boxSelect:update()

    button1.isPressed = boxSelect.objectIsSelected[button1]

    button1:draw()
    boxSelect:draw()
end

GUI:run()