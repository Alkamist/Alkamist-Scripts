function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GFX = require("GFX.AlkamistGFX")
local Button = require("GFX.Button")

GFX:initialize("Alkamist Pitch Correction", 200, 200, 1000, 700, 0)
GFX:setBackgroundColor{ 0.2, 0.2, 0.2 }

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

local analyzeButton = Button:new{
    x = 0,
    y = 0,
    w = 80,
    h = 25,
    label = "Analyze Pitch",
    color = { 0.5, 0.2, 0.1, 1.0, 0 }
}
function analyzeButton:update()
    Button.update(self)
    local mouse = self.mouse
    if mouse.buttons.left:justPressed(self) then
        if pitchEditor.isVisible then
            pitchEditor:analyzeTakePitches(pitchDetectionSettings)
        end
    end
end

local fixErrorButton = Button:new{
    x = 81,
    y = 0,
    w = 80,
    h = 25,
    label = "Fix Errors"
}
function fixErrorButton:update()
    Button.update(self)
    local mouse = self.mouse
    if mouse.buttons.left:justPressed(self) then
        if pitchEditor.isVisible then
            pitchEditor:toggleFixErrorMode()
        end
    end
end

GFX:setElements{ pitchEditor, analyzeButton, fixErrorButton }
GFX:run()