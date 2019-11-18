function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local PitchCorrectedTakeWidget = require("Pitch Correction.PitchCorrectedTakeWidget")

local pointer = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, 0))
local test = PitchCorrectedTakeWidget:new{ pointer = pointer }

test.pitchAnalyzer:prepareToAnalyzePitch()
repeat
    test.pitchAnalyzer:analyzePitch()
until test.pitchAnalyzer.isAnalyzingPitch == false

msg(test.pitchAnalyzer:encodeAsString{ time = 0, pitch = 0 })

--local Take = require("Pitch Correction.Take")
--
--local pointer = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, 0))
--local test = Take:new{ pointer = pointer }
--
--for k, v in pairs(test) do
--    msg(k .. ": " .. tostring(v))
--end