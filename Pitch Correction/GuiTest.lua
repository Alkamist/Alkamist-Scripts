function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GUI = require("GUI.AlkamistGUI")
local Button = require("GUI.Button")
local BoxSelect = require("GUI.BoxSelect")

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

local testButton1 = Button{
    mouse = GUI.getMouse(),
    x = 80,
    y = 200,
    width = 400,
    height = 400,
    label = "Fix Errors",
    --toggleOnClick = true
}
local originalTestButton1Update = testButton1.update
testButton1.update = function()
    originalTestButton1Update()
    local mouse = GUI.getMouse()
    local mouseLeftButton = mouse.getButtons().left
    if mouseLeftButton.justDragged(testButton1) then
        testButton1.changeX(mouse.getXChange())
        testButton1.changeY(mouse.getYChange())
    end
end

local thingsToSelect = {
    testButton1
}
local function isInsideFunction(box, thing)
    return box.pointIsInside(thing.getX(), thing.getY())
end
local function setSelectedFunction(thing, shouldSelect)
    if shouldSelect then
        thing.press()
    else
        thing.release()
    end
end
local function getSelectedFunction(thing)
    return thing.isPressed()
end

local boxSelect = BoxSelect()

function boxSelect.update()
    local mouse = GUI.getMouse()
    local mouseRightButton = mouse.getButtons().right
    local mouseX = mouse.getX()
    local mouseY = mouse.getY()
    local keyboardModifiers = GUI.getKeyboard().getModifiers()

    if mouseRightButton.justPressed() then
        boxSelect.startSelection(mouseX, mouseY)
    end

    if mouseRightButton.justDragged() then
        boxSelect.editSelection(mouseX, mouseY)
    end

    if mouseRightButton.justReleased() then
        boxSelect.makeSelection{
            thingsToSelect = thingsToSelect,
            isInsideFunction = isInsideFunction,
            setSelectedFunction = setSelectedFunction,
            getSelectedFunction = getSelectedFunction,
            shouldAdd = keyboardModifiers.shift.isPressed(),
            shouldInvert = keyboardModifiers.control.isPressed()
        }
    end
end

GUI.addWidgets{ testButton1, boxSelect }
GUI.run()