function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GUI = require("GUI.AlkamistGUI")
local Button = require("GUI.Button")
local PitchEditor = require("Pitch Correction.PitchEditor")

GUI:initialize{
    title = "Alkamist Pitch Correction",
    x = 200,
    y = 200,
    width = 1000,
    height = 700,
    dock = 0
}
GUI.backgroundColor = { 0.2, 0.2, 0.2 }

local pitchEditor = PitchEditor:new{
    GUI = GUI,
    x = 0,
    y = 26,
    width = 1000,
    height = 700 - 26
}

--[[local analyzeButton = Button:new{
    GUI = GUI,
    x = 0,
    y = 0,
    width = 80,
    height = 25,
    label = "Analyze Pitch",
    color = { 0.5, 0.2, 0.1, 1.0, 0 }
}
local analyzeButtonOriginalUpdate = analyzeButton.update
function analyzeButton:update()
    analyzeButtonOriginalUpdate(analyzeButton)
    if analyzeButton.justPressed then
        if pitchEditor.isVisible then
            --pitchEditor:analyzeTakePitches{
            --    windowStep = 0.04,
            --    windowOverlap = 2.0,
            --    minimumFrequency = 80,
            --    maximumFrequency = 1000,
            --    threshold = 0.2,
            --    minimumRMSdB = -60.0
            --}
        end
    end
end

local fixErrorButton = Button:new{
    GUI = GUI,
    x = 81,
    y = 0,
    width = 80,
    height = 25,
    label = "Fix Errors",
    toggleOnClick = true
}
local fixErrorButtonOriginalUpdate = fixErrorButton.update
function fixErrorButton:update()
    fixErrorButtonOriginalUpdate(fixErrorButton)
    if pitchEditor.isVisible then
        if self.justPressed then
            --pitchEditor:setFixErrorMode(true)
        elseif self.justReleased then
            --pitchEditor:setFixErrorMode(false)
        end
    end
end

GUI.widgets = { pitchEditor, analyzeButton, fixErrorButton }]]--
GUI.widgets = { pitchEditor }
GUI:run()