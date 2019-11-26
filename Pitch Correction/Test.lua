function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local Fn = require("Fn")
local GUI = require("GUI")
local PolyLine = require("PolyLine")
local Image = require("Image")

GUI.initialize{
    title = "Alkamist Pitch Correction",
    x = 400,
    y = 200,
    width = 1000,
    height = 700,
    dock = 0
}
GUI.window.setBackgroundColor(0.2, 0.2, 0.2)

local line = PolyLine.new{
    x = 100,
    y = 100,
    width = 200,
    height = 100,
}

local x = 0
for i = 1, 1000 do
    line:insertPoint{
        x = x,
        y = 200 * math.random() + 200
    }
    x = x + 1
end

function GUI.update()
    line:update()
    line:draw()
    line:endUpdate()
end

GUI.run()