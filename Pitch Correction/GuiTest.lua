function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GFX = require("GFX.Alkamist GFX")
local Button = require("GFX.Button")

GFX:init("Alkamist Pitch Correction", 200, 200, 1000, 700, 0)

local pitchDetectionSettings = {
    windowStep =       0.04,
    windowOverlap =    2.0,
    minimumFrequency = 80,
    maximumFrequency = 1000,
    threshold =        0.2,
    minimumRMSdB =     -60.0
}

local pitchEditor = require("Pitch Correction.PitchEditor"):new{
    x = 0,
    y = 25,
    w = 1000,
    h = 700 - 25
}
pitchEditor.elements = pitchEditor.elements or {}

local testButton1 = Button:new{
    x = 0,
    y = 0,
    w = 120,
    h = 25,
    label = "test1"
}
function testButton1:onMouseLeftDown()
    Button.onMouseLeftDown(self)
    if pitchEditor.isVisible then
        pitchEditor:analyzeTakePitches(pitchDetectionSettings)
    end
end
--function testButton1:onMouseLeftDrag()
--    self.x = self.x + self.GFX.mouseXChange
--    self.y = self.y + self.GFX.mouseYChange
--end


--local testButton2 = Button:new{
--    x = 20,
--    y = 20,
--    w = 120,
--    h = 25,
--    label = "test2"
--}
--table.insert(pitchEditor.elements, testButton2)

GFX:setBackgroundColor{ 0.2, 0.2, 0.2 }
--GFX:setElements{ pitchEditor }
GFX:setElements{ pitchEditor, testButton1 }
GFX:run()