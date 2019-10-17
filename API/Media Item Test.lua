function msg(m)
    reaper.ShowConsoleMsg(tostring(m).."\n")
end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Alk = require "API.Alkamist API"

for _, item in ipairs(Alk.getItems()) do
    local test1 = item:getLength()
end
local project = Alk.getProject()
local items = project:getItems()

startTime = reaper.time_precise()
for _, item in ipairs(Alk.getItems()) do
    local test1 = item:getLength()
    test1 = item:getLeftEdge()
    test1 = item:getRightEdge()
    test1 = item:getLoops()
    test1 = item:getActiveTake()
    test1 = item:getTrack():getNumber()
end
local time1 = reaper.time_precise() - startTime

startTime = reaper.time_precise()
for i = 1, reaper.CountMediaItems(0) do
    local item = reaper.GetMediaItem(0, i - 1)
    local test1 = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    test1 = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    test1 = test1 + test1
    test1 = reaper.GetMediaItemInfo_Value(item, "B_LOOPSRC") > 0
    test1 = reaper.GetActiveTake(item)
    test1 = reaper.GetMediaTrackInfo_Value(reaper.GetMediaItemTrack(item), "IP_TRACKNUMBER")
end
local time2 = reaper.time_precise() - startTime

msg(time1)
msg(time1 / time2)
msg("")
msg(time2)
msg(time2 / time1)