function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GUI = require("GUI.AlkamistGUI")
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

local testButton1 = Button:new{
    x = 50,
    y = 50,
    width = 400,
    height = 400,
    label = "Fix Errors 1"
}
local testButton2 = Button:new{
    x = 50,
    y = 50,
    width = 400,
    height = 400,
    label = "Fix Errors 2",
    toggleOnClick = true
}
testButton1.widgets = { testButton2 }

GUI.widgets = { testButton1 }
GUI:run()