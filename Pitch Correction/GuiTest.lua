function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GUI = require("GUI.AlkamistGUI")
local PitchEditor = require("Pitch Correction.PitchEditor")

GUI:initialize{
    title = "Alkamist Pitch Correction",
    x = 400,
    y = 200,
    width = 1000,
    height = 700,
    dock = 0
}
GUI.backgroundColor = { 0.2, 0.2, 0.2 }

local pitchEditor = PitchEditor:new{
    x = 50,
    y = 50,
    width = 900,
    height = 600
}

GUI.widgets = { pitchEditor }
GUI:run()