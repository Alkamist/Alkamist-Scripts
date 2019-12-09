local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")
local MouseButtons = require("MouseButtons")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

function GUI.update(dt)
    MouseButtons:updateState(dt)

    if MouseButtons.left:justStoppedDragging() then msg("left") end

    MouseButtons:updatePreviousState(dt)
end

GUI.run()