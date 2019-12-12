local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local PolyLine = require("PolyLine")

local test1 = PolyLine.new()

for i = 1, 200 do
    test1.points[i] = {
        x = i * 5,
        y = 200 + math.random() * 200
    }
end

function GUI.update(dt)
    PolyLine.update(test1, dt)
    PolyLine.draw(test1, dt)
end

GUI.run()