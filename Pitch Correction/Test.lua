function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
--local Take = require("Pitch Correction.Take")
--
--local pointer = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, 0))
--local test = Take:new{ pointer = pointer }
--
--for k, v in pairs(test) do
--    if type(v) == "function" then
--        msg(k)
--        msg(v(test))
--    end
--end

local GUI = require("GUI.AlkamistGUI")
local Button = require("GUI.Button")

GUI:initialize{
    title = "Alkamist Pitch Correction",
    x = 400,
    y = 200,
    width = 1000,
    height = 700,
    dock = 0
}
GUI:setBackgroundColor{ 0.2, 0.2, 0.2 }

--local test1 = Button:new{
--    x = 100,
--    y = 100,
--    width = 80,
--    height = 25,
--    label = "Fix Errors",
--    --toggleOnClick = true
--}

--GUI:setWidgets{ test1 }
GUI:run()