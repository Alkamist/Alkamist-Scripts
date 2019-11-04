function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GFX = require("GFX.AlkamistGFX")
local Button = require("GFX.Button")

GFX:initialize("Alkamist Pitch Correction", 200, 200, 1000, 700, 0)
GFX:setBackgroundColor{ 0.2, 0.2, 0.2 }

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
    y = 26,
    w = 1000,
    h = 700 - 26
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
    if self:justPressed() then
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
    label = "Fix Errors",
    toggleOnClick = true
}
function fixErrorButton:update()
    Button.update(self)
    if pitchEditor.isVisible then
        if self:justPressed() then
            pitchEditor:setFixErrorMode(true)
        elseif self:justReleased() then
            pitchEditor:setFixErrorMode(false)
        end
    end
end

GFX:setElements{ pitchEditor, analyzeButton, fixErrorButton }]]--

local asdf = Button:new{
    x = 0,
    y = 0,
    w = 100,
    h = 30,
    label = "test"
}

local testButton2 = Button:new{
    x = 40,
    y = 100,
    w = 100,
    h = 30,
    label = "test"
}

local testButton1 = Button:new{
    x = 81,
    y = 200,
    w = 400,
    h = 400,
    label = "Fix Errors",
    toggleOnClick = true,
    elements = {
        testButton2
    }
}
function testButton1:update()
    Button.update(self)
    local mouse = self.mouse
    if mouse.buttons.left:justDragged(testButton2) then
        self.x = self.x + mouse.xChange
    end
    if mouse.buttons.right:justPressed() then
        self:toggleVisibility()
    end
end

GFX:setElements{ asdf, testButton1 }
GFX:run()