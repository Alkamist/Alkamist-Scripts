function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local PitchAnalyzer = require("Pitch Correction.PitchAnalyzer")

local pointer = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, 0))
local test = PitchAnalyzer:new{ pointer = pointer }

test:prepareToAnalyzePitch()
repeat
    test:analyzePitch()
until test.isAnalyzingPitch == false

msg(test:encodeAsString{ time = 0, pitch = 0 })

--for k, v in pairs(test) do
--    msg(k .. ": " .. tostring(v))
--end

--local Take = require("Pitch Correction.Take")
--local TimeSeries = require("Pitch Correction.TimeSeries")

--local test = Take:new{ pointer = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, 0)) }
--
--for k, v in pairs(test) do
--    msg(k .. ": " .. tostring(v))
--end

--local test1 = TimeSeries:new()
--
--local points = test1.points
--local time = 0
--for i = 1, 1000 do
--    points[#points + 1] = {
--        time = time
--    }
--    time = time + 5
--end
--
--test1:removeDuplicatePoints()
--test1:clearPointsWithinTimeRange(2000, 3000)
--
--local testString = test1:encodeAsString{ time = 0 }
--test1:decodeFromString(testString, { time = 0 })
--msg(test1:encodeAsString{ time = 0 })
