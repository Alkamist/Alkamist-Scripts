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
    x = 5,
    y = 5,
    width = 30,
    height = 30,
    label = "1"
}
local button2 = Button.new{
    x = 5,
    y = 5,
    width = 30,
    height = 30,
    label = "2"
}
local image = Image.new{
    x = 100,
    y = 100,
    width = 200,
    height = 200,
    backgroundColor = { 0.2, 0.5, 0.7 }
}
local image2 = Image.new{
    x = 100,
    y = 100,
    width = 400,
    height = 400,
    backgroundColor = { 0.7, 0.5, 0.2 }
}


button.widgets = { button2 }
image.widgets = { button }
image2.widgets = { image }

function image:update()
    if self:justDraggedBy(GUI.mouse.buttons.right) then
        self.x = self.x + GUI.mouse.xChange
        self.y = self.y + GUI.mouse.yChange
    end
end
function image2:update()
    if self:justDraggedBy(GUI.mouse.buttons.middle) then
        self.x = self.x + GUI.mouse.xChange
        self.y = self.y + GUI.mouse.yChange
    end
end

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

GUI.window.widgets = { image2 }

GUI.run()