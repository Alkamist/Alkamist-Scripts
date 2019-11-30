local reaper = reaper
function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end
package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local Button = require("Button")

local button = Button.new(false)

for k, v in pairs(button) do msg(k) end


--local GUI = require("GUI")
--local mouse = GUI.mouse
--local mouseButtons = mouse.buttons
--local leftMouseButton = mouseButtons.left
--local middleMouseButton = mouseButtons.middle
--local rightMouseButton = mouseButtons.right
--local keyboard = GUI.keyboard
--local keyboardModifiers = keyboard.modifiers
--local shiftKey = keyboardModifiers.shift
--local controlKey = keyboardModifiers.control
--local windowsKey = keyboardModifiers.windows
--local altKey = keyboardModifiers.alt
--local keyboardKeys = GUI.keyboard.keys
--local window = GUI.window
--
----local Fn = require("Fn")
--local Button = require("Button")
--
--window:initialize("Alkamist Pitch Correction", 1000, 700, 0, 400, 200)
--window:setBackgroundColor(0.2, 0.2, 0.2)
--
--GUI.run()