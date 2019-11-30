function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GUI = require("GUI.AlkamistGUI")
local Button = require("GUI.Button")
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

local editor = PitchEditor:new{
    x = 0,
    y = 25,
    width = 1000,
    height = 700 - 25
}

local fixErrorButton = Button:new{
    x = 79,
    y = 0,
    width = 80,
    height = 25,
    label = "Fix Errors",
    toggleOnClick = true
}
editor.fixErrorMode = { get = function(self) return fixErrorButton.isPressed end }
local analyzeButton = Button:new{
    x = 0,
    y = 0,
    width = 80,
    height = 25,
    label = "Analyze Pitch",
    color = { 0.5, 0.2, 0.1, 1.0, 0 }
}
function analyzeButton:beginUpdate()
    Button.update(self)
    if self.justPressed then
        editor:analyzePitch()
    end
end

GUI.widgets = { editor, analyzeButton, fixErrorButton }
GUI:run()