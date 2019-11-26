function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local Fn = require("Fn")
local GUI = require("GUI")
local Button = require("Button")
local BoxSelect = require("BoxSelect")

GUI.initialize{
    title = "Alkamist Pitch Correction",
    x = 400,
    y = 200,
    width = 1000,
    height = 700,
    dock = 0
}
GUI.window.setBackgroundColor(0.2, 0.2, 0.2)

local testButton = Button.new{
    x = 100,
    y = 100,
    width = 200,
    height = 100,
    label = "ayylmao"
}

local dims = 30
local x = 0
local xInc = dims
local y = 0
local buttons = {}
for i = 1, 1000 do
    buttons[i] = Button.new{
        x = x,
        y = y,
        width = dims,
        height = dims,
        alpha = 0.2,
        blendMode = 1
    }
    x = x + xInc
    if x > 980 then
        x = 0
        y = y + dims
    end
end

local boxSelect = BoxSelect.new{
    thingsToSelect = buttons,
    thingIsSelected = function(self, thing)
        return thing.isPressed
    end,
    setThingSelected = function(self, thing, shouldSelect)
        thing.isPressed = shouldSelect
    end
}

function GUI.update()
    boxSelect:update()
    for i = 1, #buttons do
        local button = buttons[i]
        button:update()
        if button:justDraggedBy(GUI.keyboard.modifiers.shift) then
            button.x = button.x + GUI.mouse.xChange
            button.y = button.y + GUI.mouse.yChange
        end
    end
    for i = 1, #buttons do
        local button = buttons[i]
        button:draw()
    end
    boxSelect:draw()
    for i = 1, #buttons do
        local button = buttons[i]
        button:endUpdate()
    end
    boxSelect:endUpdate()
end

GUI.run()