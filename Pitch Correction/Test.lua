function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local Fn = require("Fn")
local GUI = require("GUI")
local Button = require("Button")

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

function GUI.update()
    --local timer = reaper.time_precise()
    testButton:update()
    if testButton:justDragged(GUI.keyboard.modifiers.shift) then
        testButton.x = testButton.x + GUI.mouse.xChange
        testButton.y = testButton.y + GUI.mouse.yChange
    end
    testButton:draw()
    --msg(reaper.time_precise() - timer)
    testButton:endUpdate()
end

GUI.run()