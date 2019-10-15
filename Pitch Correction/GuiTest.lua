package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Alk = require "API.Alkamist API"
local PitchEditor = require "Pitch Correction.PitchEditor"

local guiX = 200
local guiY = 200
local guiW = 1000
local guiH = 700
local guiDock = 0

local numPrevSelectedItems = 0
local previousGFXw = guiW
local previousGFXh = guiH

local pitchEditor = PitchEditor:new{
    x = 0,
    y = 0,
    w = guiW,
    h = guiH
}

local function Main()
    local char = gfx.getchar()

    local numSelectedItems = #Alk.selectedItems
    if #Alk.selectedItems ~= numPrevSelectedItems then
        pitchEditor:updateSelectedItems()
    end

    if gfx.w ~= previousGFXw or gfx.h ~= previousGFXh then
        pitchEditor:onResize()
    end

    pitchEditor:draw()

	if char ~= 27 and char ~= -1 then
		reaper.defer(Main)
    end
    -- Allow space to play the project.
    if char == 32 then
        reaper.Main_OnCommandEx(40044, 0, 0)
    end
    gfx.update()
    numPrevSelectedItems = numSelectedItems
    previousGFXw = gfx.w
    previousGFXh = gfx.h
end

gfx.init("Alkamist Pitch Correction", guiW, guiH, 0, guiX, guiY)
Main()