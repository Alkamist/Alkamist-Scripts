function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GFX = require("GFX.AlkamistGFX")
local Button = require("GFX.Button")

GFX:init("Alkamist Pitch Correction", 200, 200, 1000, 700, 0)
GFX:setBackgroundColor{ 0.2, 0.2, 0.2 }

local testButton = Button:new{
    x = 100,
    y = 50,
    w = 500,
    h = 400,
    label = "Analyze Pitch",
    color = { 0.5, 0.2, 0.1, 1.0, 0 }
}

local testButton2 = Button:new{
    x = 50,
    y = 100,
    w = 50,
    h = 20,
    label = "ayy",
    color = { 0.3, 0.3, 0.3, 1.0, 0 }
}
local testButton3 = Button:new{
    x = 200,
    y = 100,
    w = 50,
    h = 20,
    label = "ayy2",
    color = { 0.3, 0.3, 0.3, 1.0, 0 }
}
testButton.elements = { testButton2, testButton3 }

GFX:setElements{ testButton }
function testButton:update()
    Button.update(self)
    local mouse = self.mouse
    if mouse.buttons.right:justDragged(self) then
        self.x = self.x + mouse.xChange
        self:queueRedraw()
    end
end
--testButton2.drawBuffer = GFX:getNewDrawBuffer()
GFX:run()

--[[local pitchDetectionSettings = {
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

local analyzeButton = Button:new{
    x = 0,
    y = 0,
    w = 80,
    h = 25,
    label = "Analyze Pitch",
    color = { 0.5, 0.2, 0.1, 1.0, 0 }
}
function analyzeButton:onMouseLeftDown()
    Button.onMouseLeftDown(self)
    if pitchEditor.isVisible then
        pitchEditor:analyzeTakePitches(pitchDetectionSettings)
    end
end

local fixErrorButton = Button:new{
    x = 81,
    y = 0,
    w = 80,
    h = 25,
    label = "Fix Errors"
}
function fixErrorButton:onMouseLeftDown()
    Button.onMouseLeftDown(self)
    if pitchEditor.isVisible then
        pitchEditor:toggleFixErrorMode()
    end
end


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
GFX:setElements{ pitchEditor, analyzeButton, fixErrorButton }
GFX:run()]]--