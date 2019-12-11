local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")

GUI.initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
GUI.setBackgroundColor(0.2, 0.2, 0.2)

local ECS = require("ECS")
local Rectangle = require("Rectangle")
local ButtonState = require("ButtonState")
local ButtonDraw = require("ButtonDraw")

local RandomMover = {}
function RandomMover:requires()
    return self.RandomMover
end
function RandomMover:getDefaults()
    local defaults = {}
    defaults.x = 0
    defaults.y = 0
    return defaults
end
function RandomMover:update(dt)
    self.x = self.x + 2 - math.random() * 4
    self.y = self.y + 2 - math.random() * 4
end

local ButtonDrag = {}
function ButtonDrag:requires()
    return self.ButtonDrag
end
function ButtonDrag:getDefaults()
    local defaults = {}
    defaults.x = 0
    defaults.y = 0
    return defaults
end
function ButtonDrag:update(dt)
    if self.isPressed and GUI.mouseJustMoved then
        self.x = self.x + GUI.mouseXChange
        self.y = self.y + GUI.mouseYChange
    end
end

ECS.addSystem(RandomMover)
ECS.addSystem(Rectangle)
ECS.addSystem(ButtonState)
ECS.addSystem(ButtonDrag)
ECS.addSystem(ButtonDraw)

local buttons = {}

local x = 0
local y = 0
local size = 80
local numberOfButtons = 100
for i = 1, numberOfButtons do
    local button = {}
    button.RandomMover = true
    button.Rectangle = true
    button.ButtonState = true
    button.ButtonDrag = true
    button.ButtonDraw = true
    button.x = x
    button.y = y
    button.width = size
    button.height = size
    buttons[i] = button

    ECS.addEntity(button)

    x = x + size
    if x >= 1000 - size then
        x = 0
        y = y + size
    end
end

function GUI.update(dt)
    ECS.update(dt)
end

GUI.run()