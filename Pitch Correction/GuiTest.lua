function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GUI = require("GUI.AlkamistGUI")
--local Button = require("GUI.Button")
--local BoxSelect = require("GUI.BoxSelect")

GUI.initialize{
    title = "Alkamist Pitch Correction",
    x = 200,
    y = 200,
    width = 1000,
    height = 700,
    dock = 0
}
GUI.setBackgroundColor{ 0.2, 0.2, 0.2 }

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

GUI:addElements{ pitchEditor, analyzeButton, fixErrorButton }
GUI:run()]]--

--local asdf = Button{
--    x = 0,
--    y = 0,
--    w = 100,
--    h = 30,
--    label = "test"
--}
--local testButton2 = Button{
--    x = 40,
--    y = 100,
--    w = 100,
--    h = 30,
--    label = "test"
--}
--local testButton1 = Button{
--    x = 81,
--    y = 200,
--    w = 400,
--    h = 400,
--    label = "Fix Errors",
--    toggleOnClick = true
--}
--function testButton1.update()
--end

--function testButton1.update()
--    Button.update(self)
--    local mouse = self.mouse
--    if mouse.buttons.left:justDragged(testButton2) then
--        self:changeX(mouse:getXChange())
--    end
--    --if mouse.buttons.right:justPressed() then
--    --    self:toggleVisibility()
--    --end
--end

--local function select(thing, shouldSelect)
--    if shouldSelect then
--        thing:press()
--    else
--        thing:release()
--    end
--end
--local function isSelected(thing)
--    return thing:isPressed()
--end
--local listOfThings = { testButton1, testButton2, asdf }
--
--local boxSelect = BoxSelect:new{
--    insideColor = { 0.0, 0.0, 0.0, 0.5, 0 },
--    edgeColor = { 1.0, 1.0, 1.0, 0.8, 0 }
--}
--function boxSelect:update()
--    local mouse = self.mouse
--    local keyboardModifiers = self.keyboard.modifiers
--    if mouse.buttons.right:justPressed() then
--        self:startSelection(mouse.x, mouse.y)
--    end
--    if mouse.buttons.right:justDragged() then
--        self:editSelection(mouse.x, mouse.y)
--    end
--    if mouse.buttons.right:justReleased() then
--        self:makeSelection(listOfThings,
--                           select,
--                           isSelected,
--                           keyboardModifiers.shift:isPressed(),
--                           keyboardModifiers.control:isPressed())
--    end
--end

--GUI.addElements{ testButton1 }
--testButton1:addElements{ testButton2 }

GUI.run()