local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local MouseButtons = require("MouseButtons")
local buttons = MouseButtons.new(GUI)
local leftMouseButton = buttons.left

function GUI.update()
    leftMouseButton.update()

    if leftMouseButton.justMoved then msg("left") end
end

GUI.run()