local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

--local KeyEditor = require("KeyEditor")
--
--local test1 = KeyEditor.new{
--    x = 50, y = 50, width = 900, height = 600
--}

local Properties = require("Properties")
local Button = require("Button")
local PitchEditorTake = require("PitchEditorTake")
local PitchAnalyzer = require("PitchAnalyzer")
local PolyLine = require("PolyLine")

local take = PitchEditorTake.new()
local pitchAnalyzer = PitchAnalyzer.new{
    take = take
}
local polyLine = PolyLine.new{
    points = pitchAnalyzer.points
}

local button = Button.new{
    x = 0, y = 0, width = 70, height = 30
}
Properties.setProperty(button, "isPressed", {
    get = function(self) return self._isPressed end,
    set = function(self, v)
        self._isPressed = v
        pitchAnalyzer:analyzePitch()
    end
})

function GUI.update()
    button:update()
    take:update()
    polyLine:update()
    --polyLine:draw()
    button:draw()
end

GUI.run()