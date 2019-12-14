local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local Button = require("Button")

local button = Button.new{
    x = 100, y = 100, width = 70, height = 30
}

GUI.addWidget(button)
GUI.run()