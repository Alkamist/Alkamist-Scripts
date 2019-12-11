local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local ECS = require("ECS")

ECS.addSystem(require("RectangleMouseBehavior"))
ECS.addSystem(require("BoxSelectMouseBehavior"))
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
--    button.RectangleMouseBehavior = true
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

local pitchCorrections = {}

for i = 1, 100 do
    pitchCorrections[i] = {
        x = i * 5,
        y = 200 + math.random() * 100,
        isActive = math.random() > 0.5
    }
    pitchCorrections[i].correctedY = pitchCorrections[i].y + 100
end

local polyLine1 = {
    PolyLineDraw = true,
    PolyLineState = true,
    points = pitchCorrections,
    drawLineFn = function(self, point, nextPoint)
        if point.isActive then
            GUI.drawLine(point.x, point.y, nextPoint.x, nextPoint.y, true)
        end
    end,
    drawPointFn = function(self, point) GUI.drawCircle(point.x, point.y, 2, true, true) end
}

ECS.addEntity(polyLine1)

ECS.addEntity{
    BoxSelectMouseBehavior = true,
    BoxSelectDraw = true,
    objectsToSelect = polyLine1.points
}

function GUI.update(dt)
    ECS.update(dt)
end

GUI.run()