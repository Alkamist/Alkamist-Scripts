local reaper = reaper

local t0, t1
local function showTime(msg, a, b)
    reaper.ShowConsoleMsg(msg .. (b - a) .. "\n")
end


local item
local leftTime

t0 = reaper.time_precise()

for i = 1, 100000 do
    item = reaper.GetMediaItem(0, 0);
    leftTime = reaper.GetMediaItemInfo_Value(item, "D_POSITION");
end

t1 = reaper.time_precise()
showTime("Local before:   ", t0, t1)














--local state = { current = { "dog" } }
--
--local state2 = { current = { "dog" } }
--function state2:getCurrent() return self.current end
--
--
--local startTime = 0
--
--
--
--
--local numRuns = 1000000
--
--local time1 = 0
--for i = 1, numRuns do
--    startTime = reaper.time_precise()
--    local answer = state.current
--    time1 = time1 + reaper.time_precise() - startTime
--end
--time1 = time1 / numRuns
--
--local time2 = 0
--for i = 1, numRuns do
--    startTime = reaper.time_precise()
--    local answer = state2:getCurrent()
--    time2 = time2 + reaper.time_precise() - startTime
--end
--time2 = time2 / numRuns
--
--msg(time1)
--msg(time1 / time2)
--msg("")
--msg(time2)
--msg(time2 / time1)







--[[package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
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
GFX:run()]]--