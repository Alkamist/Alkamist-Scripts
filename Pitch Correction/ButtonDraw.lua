local tiny = require("tiny")
local GUI = require("GUI")

local ButtonDraw = tiny.processingSystem()

ButtonDraw.filter = tiny.requireAll(
    "x", "y", "width", "height",
    "isPressed", "isGlowing",
    "bodyColor", "outlineColor", "pressedColor", "highlightColor"
)

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
