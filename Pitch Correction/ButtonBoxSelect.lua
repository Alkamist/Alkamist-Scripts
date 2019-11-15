function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GUI = require("GUI.AlkamistGUI")
local Button = require("GUI.Button")
local BoxSelect = require("GUI.BoxSelect")

GUI:initialize{
    title = "Alkamist Pitch Correction",
    x = 200,
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
    label = "Fix Errors",
    --toggleOnClick = true
}
local originalTestButton1Update = testButton1.update
function testButton1:update()
    originalTestButton1Update(self)
    local mouse = self.GUI.mouse
    local mouseLeftButton = mouse.leftButton
    if mouseLeftButton:justDraggedWidget(self) then
        self.x = self.x + mouse.xChange
        self.y = self.y + mouse.yChange
    end
end
local testButton2 = Button:new{
    x = 50,
    y = 50,
    width = 400,
    height = 400,
    label = "Fix Errors 2",
    toggleOnClick = true
}
local testButton3 = Button:new{
    x = 50,
    y = 50,
    width = 400,
    height = 400,
    label = "Fix Errors 3",
    --toggleOnClick = false
}
testButton2.widgets = { testButton3 }
testButton1.widgets = { testButton2 }

local thingsToSelect = { testButton1, testButton2, testButton3 }
local function isInsideFunction(box, thing)
    return box:pointIsInside(thing.absoluteX, thing.absoluteY)
end
local function setSelectedFunction(thing, shouldSelect)
    if shouldSelect then
        thing.isPressed = true
    else
        thing.isPressed = false
    end
end
local function getSelectedFunction(thing)
    return thing.isPressed
end

local boxSelect = BoxSelect:new{
    GUI = GUI
}

function boxSelect:update()
    local mouse = self.GUI.mouse
    local mouseRightButton = mouse.rightButton
    local mouseX = mouse.x
    local mouseY = mouse.y
    local shiftKey = GUI.keyboard.shiftKey
    local controlKey = GUI.keyboard.controlKey

    if mouseRightButton.justPressed then
        boxSelect:startSelection(mouseX, mouseY)
    end

    if mouseRightButton.justDragged then
        boxSelect:editSelection(mouseX, mouseY)
    end

    if mouseRightButton.justReleased then
        boxSelect:makeSelection{
            thingsToSelect = thingsToSelect,
            isInsideFunction = isInsideFunction,
            setSelectedFunction = setSelectedFunction,
            getSelectedFunction = getSelectedFunction,
            shouldAdd = shiftKey.isPressed,
            shouldInvert = controlKey.isPressed
        }
    end
end

GUI.widgets = { testButton1, boxSelect }
GUI:run()