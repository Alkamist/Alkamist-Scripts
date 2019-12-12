local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local ECS = require("DefineSystemOrder")

local test1 = {
    KeyBackgroundState = true,
    KeyBackgroundDraw = true,
    x = 50,
    y = 50,
    width = 900,
    height = 600
}

ECS.addEntity(test1)

function GUI.update(dt)
    ECS.update(dt)
end

GUI.run()