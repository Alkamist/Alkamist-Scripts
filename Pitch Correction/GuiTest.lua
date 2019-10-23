function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GFX = require("GFX.Alkamist GFX")

GFX:init("Alkamist Pitch Correction", 200, 200, 1000, 700, 0)

local pitchEditor = require("Pitch Correction.PitchEditor"):new{
    x = 200,
    y = 200,
    w = 600,
    h = 400,
    layer = 0
}

GFX:setBackgroundColor{ 0.2, 0.2, 0.2 }
GFX:setElements{ pitchEditor }
GFX:run()