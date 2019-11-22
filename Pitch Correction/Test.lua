function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GUI = require("GUI.AlkamistGUI")
local EditablePolyLine = require("GUI.EditablePolyLine")
local Button = require("GUI.Button")

GUI:initialize{
    title = "Alkamist Pitch Correction",
    x = 400,
    y = 200,
    width = 1000,
    height = 700,
    dock = 0
}
GUI.backgroundColor = { 0.2, 0.2, 0.2 }

local line = EditablePolyLine:new{
    x = 50,
    y = 50,
    width = 1000 - 100,
    height = 700 - 100
}

local x = 0
local inc = line.width / 100
for i = 1, 100 do
    line:insertPoint{
        x = x,
        y = 200 * math.random() + 200
    }
    x = x + inc
end

local analyzeButton = Button:new{
    x = 100,
    y = 100,
    width = 200,
    height = 200,
    label = "Analyze Pitch",
    color = { 0.5, 0.2, 0.1, 1.0, 0 }
}
--local analyzeButton2 = Button:new{
--    x = 50,
--    y = 50,
--    width = 150,
--    height = 150,
--    label = "Analyze Pitch 2",
--    color = { 0.3, 0.6, 0.2, 1.0, 0 }
--}
--analyzeButton.childWidgets = { analyzeButton2 }

GUI.widgets = { line, analyzeButton }
--GUI.widgets = { analyzeButton }
GUI:run()