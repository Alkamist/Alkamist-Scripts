local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local Button = require("Button")

local x = 0
local y = 0
local size = 40
local numberOfButtons = 200
for i = 1, numberOfButtons do
    local button = Button:new()
    button.x = x
    button.y = y
    button.width = size
    button.height = size

    function button:onLeftMouseButtonJustDragged()
        self.x = self.x + GUI.mouseXChange
        self.y = self.y + GUI.mouseYChange
    end
    function button:onUpdate(dt)
        self.x = self.x + 2 - math.random() * 4
        self.y = self.y + 2 - math.random() * 4
        Button.onUpdate(self, dt)
    end

    GUI.addWidget(button)

    x = x + size
    if x >= 1000 - size then
        x = 0
        y = y + size
    end
end

GUI.run()