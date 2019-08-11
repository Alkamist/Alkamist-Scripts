package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local PCFunc = require "Pitch Correction.Helper Functions.Pitch Correction Functions"
local Reaper = require "Various Functions.Reaper Functions"



local label = "Correct Pitch of Audio Items on Tracks Received by Selected MIDI Items.lua"

-- Pitch detection settings:
local settings = {}
settings.maximumLength = 300
settings.windowStep = 0.04
settings.overlap = 2.0
settings.minimumFrequency = 60
settings.maximumFrequency = 1000
settings.YINThresh = 0.2
settings.lowRMSLimitdB = -60



reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

PCFunc.saveSettingsInExtState(settings)
local selectedItems = Reaper.getSelectedItems()

for i = 1, #selectedItems do
    local item = selectedItems[i]
    PCFunc.correctPitchBasedOnMIDIItem(item, settings)
end

Reaper.restoreSelectedItems(selectedItems)

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(label, -1)
reaper.UpdateArrange()