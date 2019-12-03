local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local MouseButtons = require("MouseButtons")
local DrawableButton = require("DrawableButton")
local Drawable = require("Drawable")

local buttons = MouseButtons(GUI)
local leftMouseButton = buttons.left

local drawableState = { alpha = 1, blendMode = 0 }
Drawable(leftMouseButton, drawableState)

local drawableButtonState = {
    width = 100,
    height = 40,
    bodyColor = { 0.4, 0.4, 0.4, 1, 0 },
    outlineColor = { 0.15, 0.15, 0.15, 1, 0 },
    highlightColor = { 1, 1, 1, 0.15, 1 },
    pressedColor = { 1, 1, 1, -0.15, 1 },
}
DrawableButton(leftMouseButton, drawableButtonState)

local oldUpdateState = leftMouseButton.updateState
function leftMouseButton.updateState()
    oldUpdateState()
    drawableState.x = GUI.mouseX
    drawableState.y = GUI.mouseY
end

function GUI.update()
    leftMouseButton.updateState()
    leftMouseButton.draw()
    leftMouseButton.update()
end

GUI.run()