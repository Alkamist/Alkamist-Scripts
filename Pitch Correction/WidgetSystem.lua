local tiny = require("tiny")

local gfx = gfx

local WidgetSystem = tiny.processingSystem()
WidgetSystem.filter = tiny.requireAll("draw", "preProcess", "process", "postProcess")

function WidgetSystem:preProcess(e, dt)
    e:preProcess(dt)
end

function WidgetSystem:process(e, dt)
    e:process(dt)

    local x, y, a, mode, dest = gfx.x, gfx.y, gfx.a, gfx.mode, gfx.dest
    e:draw(dt)
    gfx.x, gfx.y, gfx.a, gfx.mode, gfx.dest = x, y, a, mode, dest
end

function WidgetSystem:postProcess(e, dt)
    e:postProcess(dt)
end

return WidgetSystem