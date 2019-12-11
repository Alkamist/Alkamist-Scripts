local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local ECS = require("ECS")

ECS.addSystem(require("Rectangle"))
ECS.addSystem(require("BoxSelectState"))
ECS.addSystem(require("ButtonMouseBehavior"))
ECS.addSystem(require("PolyLineState"))
ECS.addSystem(require("ButtonDraw"))
ECS.addSystem(require("PolyLineDraw"))
ECS.addSystem(require("BoxSelectDraw"))

--local buttons = {}
--
--local x = 0
--local y = 0
--local size = 60
--local numberOfButtons = 100
--for i = 1, numberOfButtons do
--    local button = {}
--    button.Rectangle = true
--    button.ButtonMouseBehavior = true
--    button.ButtonDraw = true
--    button.x = x
--    button.y = y
--    button.width = size
--    button.height = size
--    buttons[i] = button
--
--    ECS.addEntity(button)
--
--    x = x + size
--    if x >= 1000 - size then
--        x = 0
--        y = y + size
--    end
--end

local polyLine1 = {
    PolyLineState = true,
    PolyLineDraw = true,
    points = {}
}
for i = 1, 100 do
    local point = {
        x = i * 5,
        y = 200 + math.random() * 100
    }
    polyLine1.points[i] = point
end

ECS.addEntity(polyLine1)

ECS.addEntity{
    BoxSelectState = true,
    BoxSelectDraw = true,
--    objectsToSelect = buttons
}

function GUI.update(dt)
    ECS.update(dt)
end

GUI.run()