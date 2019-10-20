package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GFX = require("GFX.Alkamist GFX")

GFX:init{
    title = "Alkamist Pitch Correction",
    x = 200,
    y = 200,
    width = 1000,
    height = 700,
    dock = 0
}

local pitchEditor = require("Pitch Correction.PitchEditor"):new{
    GFX = GFX,
    x = 0,
    y = 0,
    width = 1000,
    height = 700
}

GFX:setChildren{ pitchEditor }
GFX:setPlayKey("Space")
GFX:run()