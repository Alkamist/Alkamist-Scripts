function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GUI = require("GUI.AlkamistGUI")
--local Button = require("GUI.Button")

GUI:initialize{
    title = "Alkamist Pitch Correction",
    x = 400,
    y = 200,
    width = 1000,
    height = 700,
    dock = 0
}

--local testButton = Button:new{
--    x = 100,
--    y = 100,
--    width = 80,
--    height = 25,
--    label = "Fix Errors"
--}
--local function pointIsInsideBox(pointX, pointY, boxX, boxY, boxW, boxH)
--    return pointX >= boxX and pointX <= boxX + boxW
--       and pointY >= boxY and pointY <= boxY + boxH
--end
--local function mouseIsInsideBox(boxX, boxY, boxW, boxH)
--    return pointIsInsideBox(GUI.mouse.getX(), GUI.mouse.getY(), boxX, boxY, boxW, boxH)
--end

function GUI:onUpdate()
    if GUI.mouse.buttons.left.justStoppedDragging then msg("left") end
end

GUI:run()