package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Alk = require "API.Alkamist API"
local GFX = require "GFX.Alkamist GFX"

local PitchEditor = require "Pitch Correction.PitchEditor"
local pitchEditor = PitchEditor:new{
    x = 0,
    y = 0,
    w = 1000,
    h = 700
}

local numPrevSelectedItems = 0
local function Main()
    local numSelectedItems = #Alk.selectedItems
    if #Alk.selectedItems ~= numPrevSelectedItems then
        pitchEditor:updateSelectedItems()
    end
    numPrevSelectedItems = numSelectedItems
end

GFX.children = { pitchEditor }
GFX.playKey = "Space"
GFX.runHook = Main
GFX.run("Alkamist Pitch Correction", 200, 200, 1000, 700, 0)