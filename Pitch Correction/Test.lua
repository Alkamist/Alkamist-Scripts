local reaper = reaper
function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end
package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local GUI = require("GUI")
local mouse = GUI.mouse
local mouseButtons = mouse.buttons
local leftMouseButton = mouseButtons.left
local middleMouseButton = mouseButtons.middle
local rightMouseButton = mouseButtons.right
local keyboard = GUI.keyboard
local keyboardModifiers = keyboard.modifiers
local shiftKey = keyboardModifiers.shift
local controlKey = keyboardModifiers.control
local windowsKey = keyboardModifiers.windows
local altKey = keyboardModifiers.alt
local keyboardKeys = GUI.keyboard.keys
local window = GUI.window

--local Fn = require("Fn")
local Button = require("Button")

window:initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
window:setBackgroundColor(0.2, 0.2, 0.2)

--local button1 = Button.new{
--    x = 50,
--    y = 50,
--    width = 100,
--    height = 40,
--    label = "ayylmao"
--}

local numberOfButtons = 2000
local x = 0
local y = 0
local buttonSize = 15
local buttons = {}
for i = 1, numberOfButtons do
    buttons[i] = Button.new{
        x = x,
        y = y,
        width = buttonSize,
        height = buttonSize
    }
    local oldUpdate = buttons[i].update
    buttons[i].update = function(self)
        oldUpdate(self)
        if self:controlJustDragged(self.pressControl) then
            self.x = self.x + mouse.xChange
            self.y = self.y + mouse.yChange
        end
    end
    x = x + buttonSize
    if x > 1000 - buttonSize then
        x = 0
        y = y + buttonSize
    end
end

function GUI.update()
    for i = 1, numberOfButtons do buttons[i]:update() end
    for i = 1, numberOfButtons do buttons[i]:draw() end
    for i = 1, numberOfButtons do buttons[i]:endUpdate() end
end

GUI.run()