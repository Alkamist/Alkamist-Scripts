local tiny = require("tiny")
local GUI = require("GUI")

local ButtonDraw = tiny.processingSystem()

ButtonDraw.filter = tiny.requireAll(
    "x", "y", "width", "height",
    "isPressed", "isGlowing",
    "bodyColor", "outlineColor", "pressedColor", "highlightColor"
)

--function ButtonDraw:getDefault()
--    local e = {}
--    e.x = 0
--    e.y = 0
--    e.width = 0
--    e.height = 0
--    e.isPressed = false
--    e.isGlowing = false
--    e.bodyColor = { 0.4, 0.4, 0.4, 1, 0 }
--    e.outlineColor = { 0.15, 0.15, 0.15, 1, 0 }
--    e.pressedColor = { 1, 1, 1, 0.1, 1 }
--    e.highlightColor = { 1, 1, 1, -0.15, 1 }
--    return e
--end

function ButtonDraw:process(e, dt)
    local x, y, w, h = e.x, e.y, e.width, e.height

    -- Draw the body.
    GUI.setColor(e.bodyColor)
    GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, true)

    -- Draw a dark outline around.
    GUI.setColor(e.outlineColor)
    GUI.drawRectangle(x, y, w, h, false)

    -- Draw a light outline around.
    GUI.setColor(e.highlightColor)
    GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, false)

    if e.isPressed then
        GUI.setColor(e.pressedColor)
        GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, true)

    elseif e.isGlowing then
        GUI.setColor(e.highlightColor)
        GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, true)
    end
end

return ButtonDraw
