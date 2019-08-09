local label = "Correct Pitch of Audio Items on Tracks Received by Selected MIDI Items.lua"

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
require "Helper Functions.Pitch Correction Functions"



local edgePointSpacing = 0.01

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

saveSettingsInExtState(settings)
local selectedItems = getSelectedItems()

for i = 1, #selectedItems do
    local item = selectedItems[i]
    correctPitchBasedOnMIDIItem(item, settings)
end

restoreSelectedItems(selectedItems)

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(label, -1)
reaper.UpdateArrange()