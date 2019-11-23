function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GUI = require("GUI.AlkamistGUI")
local Button = require("GUI.Button")

GUI.initialize{
    title = "Alkamist Pitch Correction",
    x = 400,
    y = 200,
    width = 1000,
    height = 700,
    dock = 0
}

local testButton = Button.new{
    x = 100,
    y = 100,
    width = 80,
    height = 25,
    label = "Fix Errors"
}

local function pointIsInsideBox(point, box)
    local pointX, pointY = point.x, point.y
    local boxX, boxY, boxW, boxH = box.x, box.y, box.width, box.height

    return pointX >= boxX and pointX <= boxX + boxW
       and pointY >= boxY and pointY <= boxY + boxH
end
local function mouseIsInsideBox(box)
    local mousePoint = { x = GUI.mouse.getX(), y = GUI.mouse.getY() }
    return pointIsInsideBox(mousePoint, box)
end
--local function pointIsInsideBox(pointX, pointY, boxX, boxY, boxW, boxH)
--    return pointX >= boxX and pointX <= boxX + boxW
--       and pointY >= boxY and pointY <= boxY + boxH
--end
--local function mouseIsInsideBox(boxX, boxY, boxW, boxH)
--    return pointIsInsideBox(GUI.mouse.getX(), GUI.mouse.getY(), boxX, boxY, boxW, boxH)
--end

local buttonIsClicked = {}

function GUI.onMousePress(button)
    if button == "left" then
        if mouseIsInsideBox(testButton) then
            buttonIsClicked[testButton] = true
            Button.press(testButton)
        end
    end
end
function GUI.onMouseRelease(button)
    if button == "left" then
        buttonIsClicked[testButton] = false
        Button.release(testButton)
    end
end
function GUI.onMouseMove(xChange, yChange)
    if buttonIsClicked[testButton] then
        testButton.x = testButton.x + xChange
        testButton.y = testButton.y + yChange
    end
    if mouseIsInsideBox(testButton) then
        Button.glow(testButton)
    else
        Button.unGlow(testButton)
    end
end

function GUI.onDraw()
    Button.draw(testButton)
end

GUI.run()