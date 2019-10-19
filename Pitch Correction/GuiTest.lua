package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Alk = require("API.Alkamist API"):new()
local GFX = require("GFX.Alkamist GFX"):new("Alkamist Pitch Correction", 200, 200, 1000, 700, 0)

local pitchEditor = require("Pitch Correction.PitchEditor"):new()

local numPrevSelectedItems = 0
local function Main()
    local numSelectedItems = #Alk:getSelectedItems()
    if numSelectedItems ~= numPrevSelectedItems then
        pitchEditor:updateSelectedItems()
    end
    numPrevSelectedItems = numSelectedItems
end

GFX:setChildren{ pitchEditor }
GFX:setPlayKey("Space")
GFX:setPreHook(Main)
GFX:run()