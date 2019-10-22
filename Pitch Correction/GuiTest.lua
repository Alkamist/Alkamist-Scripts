function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GFX = require("GFX.Alkamist GFX")

GFX:init("Alkamist Pitch Correction", 200, 200, 1000, 700, 0)

local pitchEditor = require("Pitch Correction.PitchEditor"):new{
    GFX = GFX,
    x = 0,
    y = 0,
    w = 1000,
    h = 700
}

GFX:setBackgroundColor{ 0.2, 0.2, 0.2 }
GFX:setChildren{ pitchEditor }
GFX:run()