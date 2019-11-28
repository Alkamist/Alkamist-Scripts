function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local Fn = require("Fn")
local GUI = require("GUI")
local Button = require("Button")
--local PolyLine = require("PolyLine")
--local Image = require("Image")
--local BoxSelect = require("BoxSelect")

GUI.window:initialize{
    title = "Alkamist Pitch Correction",
    x = 400,
    y = 200,
    width = 1000,
    height = 700,
    dock = 0
}
GUI.window:setBackgroundColor(0.2, 0.2, 0.2)

local button1 = Button.new{
    x = 50,
    y = 50,
    width = 50,
    height = 50,
    label = "1"
}
local button2 = Button.new{
    x = 50,
    y = 50,
    width = 50,
    height = 50,
    label = "2"
}
button1.widgets = { button2 }

button2.relativeX = button2.x
button2:setProperty("x", {
    get = function(self) return self.relativeX + button1.x end,
    set = function(self, v) self.relativeX = v - button1.x end
})

button2.relativeY = button2.y
button2:setProperty("y", {
    get = function(self) return self.relativeY + button1.y end,
    set = function(self, v) self.relativeY = v - button1.y end
})

function button1:update()
    Button.update(self)
    if GUI.mouse.buttons.left:justDraggedWidget(self) then
        self.x = self.x + GUI.mouse.xChange
        self.y = self.y + GUI.mouse.yChange
    end
end

GUI.window.widgets = { button1 }
GUI.run()
--
--local button = Button.new{
--    x = 5,
--    y = 5,
--    width = 30,
--    height = 30,
--    label = "1"
--}
--local button2 = Button.new{
--    x = 5,
--    y = 5,
--    width = 30,
--    height = 30,
--    label = "2"
--}
--local image = Image.new{
--    x = 100,
--    y = 100,
--    width = 200,
--    height = 200,
--    backgroundColor = { 0.2, 0.5, 0.7 }
--}
--local image2 = Image.new{
--    x = 100,
--    y = 100,
--    width = 400,
--    height = 400,
--    backgroundColor = { 0.7, 0.5, 0.2 }
--}
--
--button.widgets = { button2 }
--image.widgets = { button }
--image2.widgets = { image }
--
--local imageX = image.x
--local imageY = image.y
--local xRandom = 0
--local yRandom = 0
--
--function image:update()
--    xRandom = 5 - math.random() * 10
--    yRandom = 5 - math.random() * 10
--
--    if self:justDraggedBy(GUI.mouse.buttons.right) then
--        imageX = imageX + GUI.mouse.xChange
--        imageY = imageY + GUI.mouse.yChange
--    end
--    self.x = image2.x + imageX + xRandom
--    self.y = image2.y + imageY + yRandom
--end
--function image2:update()
--    if self:justDraggedBy(GUI.mouse.buttons.middle) then
--        self.x = self.x + GUI.mouse.xChange
--        self.y = self.y + GUI.mouse.yChange
--    end
--end
--
--local boxSelect = BoxSelect.new()

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

--GUI.window.widgets = { image2, boxSelect }
--
--GUI.run()