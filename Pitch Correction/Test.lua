local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local tiny = require("tiny")

local ButtonState = require("ButtonState")
local ButtonDrag = require("ButtonDrag")
local ButtonDraw = require("ButtonDraw")
local PreviousState = require("PreviousState")

local world = tiny.world()
world:add(ButtonState, ButtonDrag, ButtonDraw, PreviousState)

local button1 = {
    x = 50,
    y = 50,
    width = 100,
    height = 40,
    isPressed = true,
    isGlowing = false,
    bodyColor = { 0.4, 0.4, 0.4, 1, 0 },
    outlineColor = { 0.15, 0.15, 0.15, 1, 0 },
    highlightColor = { 1, 1, 1, 0.1, 1 },
    pressedColor = { 1, 1, 1, -0.15, 1 }
}
world:addEntity(button1)

function GUI.update(dt)
    world:update(dt)

    gfx.x = 1
    gfx.y = 1
    gfx.set(0.7, 0.7, 0.7, 1, 0)
    gfx.drawnumber(1 / dt, 1)
end

GUI.run()