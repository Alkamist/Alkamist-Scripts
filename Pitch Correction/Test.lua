function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local Fn = require("Fn")
local GUI = require("GUI")
--local PolyLine = require("PolyLine")
local Image = require("Image")
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

local button = Button.new{
    x = 50,
    y = 50,
    width = 200,
    height = 100,
}
local image = Image.new{
    x = 200,
    y = 200,
    width = 1000,
    height = 1000,
}

--local line = PolyLine.new{
--    x = 0,
--    y = 0,
--    width = 200,
--    height = 100,
--}
--local x = 0
--for i = 1, 1000 do
--    PolyLine.insertPoint(line, {
--        x = x,
--        y = 200 * math.random()
--    })
--    x = x + 1
--end

function GUI.update()
    Button.update(button)
    Fn.callWithChanges(Button.update, button, { x = button.x + image.x, y = button.y + image.y })
    Image.update(image)

    Button.draw(button)
    Image.draw(image, function() Button.draw(button) end)

    Button.endUpdate(button)
    Image.endUpdate(image)
end

GUI.run()