function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local Fn = require("Fn")
local GUI = require("GUI")
--local PolyLine = require("PolyLine")
--local Image = require("Image")
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

--local button = Button.new{
--    x = 50,
--    y = 50,
--    width = 200,
--    height = 100
--}
--local image = Image.new{
--    x = 200,
--    y = 200,
--    width = 1000,
--    height = 1000,
--}

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

--local oldX = button:x()
--button.x = function(self, v)
--    if v ~= nil then oldX = v end
--    return oldX + 30 * math.random()
--end

local mouse = GUI.mouse
local leftMouseButton = mouse.buttons.left

local x = 0
local y = 0
local buttons = {}
for i = 1, 3000 do
    buttons[i] = Button.new{
        x = x,
        y = y,
        width = 10,
        height = 10
    }
    local oldX = buttons[i]:x()
    buttons[i].x = function(self, v)
        if v ~= nil then oldX = v end
        return oldX + 3 * math.random()
    end
    local oldY = buttons[i]:y()
    buttons[i].y = function(self, v)
        if v ~= nil then oldY = v end
        return oldY + 3 * math.random()
    end
    local oldUpdate = buttons[i].update
    buttons[i].update = function(self)
        oldUpdate(self)
        if self:justDraggedBy(leftMouseButton) then
            self:x(oldX + mouse.xChange)
            self:y(oldY + mouse.yChange)
        end
    end
    x = x + 10
    if x > 990 then
        x = 0
        y = y + 10
    end
end

function GUI.update()
    local numberOfButtons = #buttons
    for i = 1, numberOfButtons do buttons[i]:update() end
    for i = 1, numberOfButtons do buttons[i]:draw() end
    for i = 1, numberOfButtons do buttons[i]:endUpdate() end
end

GUI.run()