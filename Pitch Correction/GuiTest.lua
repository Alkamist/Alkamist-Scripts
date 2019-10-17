package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Alk = require "API.Alkamist API"
local GFX = require "GFX.Alkamist GFX"

GFX.init("Alkamist Pitch Correction", 200, 200, 1000, 700, 0)

local PitchEditor = require "Pitch Correction.PitchEditor"
local pitchEditor = PitchEditor:new()

local numPrevSelectedItems = 0
local function Main()
    local numSelectedItems = #Alk.getSelectedItems()
    if numSelectedItems ~= numPrevSelectedItems then
        pitchEditor:updateSelectedItems()
    end
    numPrevSelectedItems = numSelectedItems
end

GFX.children = { pitchEditor }
GFX.playKey = "Space"
GFX.runHook = Main
GFX.run()