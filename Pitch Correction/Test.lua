local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local ECS = require("ECS")

local MouseButtons = require("MouseButtons")

--local x = 0
--local y = 0
--local buttons = {}
--for i = 1, 5000 do
--    buttons[i] = {
--        Position = true,
--        Button = true,
--        shouldDraw = true,
--        x = x, y = y, width = 10, height = 10
--    }
--    ECS.addEntity(buttons[i])
--
--    x = x + 10
--    if x > 990 then
--        x = 0
--        y = y + 10
--    end
--end

function GUI.update(dt)
    --for i = 1, 5000 do
    --    buttons[i].x = buttons[i].x + 2.5 - math.random() * 5
    --    buttons[i].y = buttons[i].y + 2.5 - math.random() * 5
    --end
    ECS.update(dt)

    if MouseButtons.left.justDragged then msg("left") end

    --gfx.x = 1
    --gfx.y = 1
    --gfx.set(0.7, 0.7, 0.7, 1, 0)
    --gfx.drawnumber(1 / dt, 1)
end

GUI.run()