local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local Button = require("Button")
local BoxSelect = require("BoxSelect")
local PolyLine = require("PolyLine")

local button = Button.new{
    x = 300, y = 300, width = 100, height = 70
}
local line = PolyLine.new()

for i = 1, 200 do
    local points = line.points
    points[i] = {
        x = i * 3,
        y = 200 + math.random() * 200
    }
end

local boxSelect = BoxSelect.new{
    objectsToSelect = line.points
}

GUI.addWidget(line)
GUI.addWidget(boxSelect)
GUI.addWidget(button)
GUI.run()