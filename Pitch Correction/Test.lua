function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GUI = require("GUI.AlkamistGUI")
local Button = require("GUI.Button")
local BoxSelect = require("GUI.BoxSelect")
local Image = require("GUI.Image")

GUI.initialize{
    title = "Alkamist Pitch Correction",
    x = 400,
    y = 200,
    width = 1000,
    height = 700,
    dock = 0
}
GUI.window.setBackgroundColor{ 0.2, 0.2, 0.2 }

local testButton = Button.new{
    x = 100,
    y = 100,
    width = 80,
    height = 25,
    label = "Fix Errors",
    pressControl = GUI.mouse.buttons.left
}

local boxSelect = BoxSelect.new{
    selectionControl = GUI.mouse.buttons.right,
    additiveControl = GUI.keyboard.modifiers.shift,
    inversionControl = GUI.keyboard.modifiers.control
}

local image = Image.new{
    x = 300,
    y = 300,
    width = 400,
    height = 400,
    backgroundColor = { 0.5, 0.3, 0.2, 1, 0 }
}

function GUI.onUpdate()
    Button.update(testButton)
    BoxSelect.update(boxSelect)
end
function GUI.onDraw()
    Button.draw(testButton)
    BoxSelect.draw(boxSelect)
    Image.draw(image, function() Button.draw(testButton) end)
end
function GUI.onEndUpdate()
    Button.endUpdate(testButton)
    Image.endUpdate(image)
end


GUI.run()