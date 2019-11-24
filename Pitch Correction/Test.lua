function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GUI = require("GUI.AlkamistGUI")
local Button = require("GUI.Button")

GUI:initialize{
    title = "Alkamist Pitch Correction",
    x = 400,
    y = 200,
    width = 1000,
    height = 700,
    dock = 0
}

local testButton = Button:new{
    x = 100,
    y = 100,
    width = 80,
    height = 25,
    label = "Fix Errors",
    pressControl = GUI.mouse.buttons.left
}

function GUI:onUpdate()
    testButton:update()
end
function GUI:onDraw()
    testButton:draw()
end
function GUI:onEndUpdate()
    testButton:endUpdate()
end


GUI:run()