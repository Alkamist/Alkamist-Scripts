local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local KeyEditor = require("KeyEditor")

local test1 = KeyEditor.new{
    x = 50, y = 50, width = 900, height = 600
}

--local Properties = require("Properties")
--local PolyLine = require("PolyLine")
--
--local test1 = PolyLine.new()
--
--for i = 1, 5000 do
--    test1.points[i] = {
--        x = i * 0.2,
--        y = 200 + math.random() * 200
--    }
--end

function GUI.update(dt)
    test1:update(dt)
    test1:draw(dt)
end

GUI.run()