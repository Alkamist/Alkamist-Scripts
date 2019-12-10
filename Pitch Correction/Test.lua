local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local Button = require("Button")
local BoxSelect = require("BoxSelect")

local buttons = {}
local x = 400
local y = 400
local size = 12
local numberOfButtons = 100
for i = 1, numberOfButtons do
    local button = Button:new()
    button.x = x
    button.y = y
    button.width = size
    button.height = size
    buttons[i] = button

    --function button:onLeftMouseButtonJustDragged()
    --    if self.isPressed then
    --        self.x = self.x + GUI.mouseXChange
    --        self.y = self.y + GUI.mouseYChange
    --    end
    --end
    function button:onLeftMouseButtonJustPressedWidget() end
    function button:onLeftMouseButtonJustReleasedWidget() end
    function button:onUpdate(dt)
        self.x = self.x + 2 - math.random() * 4
        self.y = self.y + 2 - math.random() * 4
        Button.onUpdate(self, dt)
    end

    GUI.addWidget(button)

    --x = x + size
    --if x >= 1000 - size then
    --    x = 0
    --    y = y + size
    --end
end

local boxSelect = BoxSelect:new()
boxSelect.objectsToSelect = buttons

function boxSelect:setObjectSelected(object, shouldSelect)
    object.isPressed = shouldSelect
end
function boxSelect:objectIsSelected(object)
    return object.isPressed
end

GUI.addWidget(boxSelect)

GUI.run()