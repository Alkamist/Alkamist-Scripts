local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local tiny = require("tiny")

local WidgetSystem = tiny.processingSystem()
WidgetSystem.filter = tiny.requireAll("x", "y")

function WidgetSystem:process(e, dt)
    e.x = e.x + dt

    gfx.x = 300
    gfx.y = 300
    gfx.set(0.7, 0.7, 0.7, 1, 0)
    gfx.drawnumber(e.x, 1)
end

local test1 = {
    x = 50,
    y = 50
}

local world = tiny.world(WidgetSystem, test1)

function GUI.update(dt)
    world:update(dt)

    gfx.x = 1
    gfx.y = 1
    gfx.set(0.7, 0.7, 0.7, 1, 0)
    gfx.drawnumber(1 / dt, 1)
end

GUI.run()