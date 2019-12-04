local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local MouseButtons = require("MouseButtons")
local leftMouseButton = MouseButtons.left

function GUI.update()
    for k, v in pairs(MouseButtons) do
        v:update()

        if v.justPressed then msg(k) end
    end
end

GUI.run()