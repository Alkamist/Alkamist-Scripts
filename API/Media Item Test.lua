package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Alk = require "API.Alkamist API"

local projects = Alk.getProjects()
msg(#projects)

local items = Alk.getItems()
msg(#items)
for _, item in ipairs(items) do
    msg(item:isSelected())
end






--local startTime = 0
--for _, item in ipairs(Alk.getItems()) do
--    local test1 = item:getLength()
--end
--local project = Alk.getProject()
--local items = project:getItems()
--
--startTime = reaper.time_precise()
--for _, item in ipairs(Alk.getItems()) do
--    local test1 = item:getLength()
--    test1 = item:getLeftEdge()
--    test1 = item:getRightEdge()
--    test1 = item:getLoops()
--    test1 = item:getActiveTake()
--    test1 = item:getTrack():getNumber()
--end
--local time1 = reaper.time_precise() - startTime
--
--startTime = reaper.time_precise()
--for i = 1, reaper.CountMediaItems(0) do
--    local item = reaper.GetMediaItem(0, i - 1)
--    local test1 = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
--    test1 = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
--    test1 = test1 + test1
--    test1 = reaper.GetMediaItemInfo_Value(item, "B_LOOPSRC") > 0
--    test1 = reaper.GetActiveTake(item)
--    test1 = reaper.GetMediaTrackInfo_Value(reaper.GetMediaItemTrack(item), "IP_TRACKNUMBER")
--end
--local time2 = reaper.time_precise() - startTime
--
--msg(time1)
--msg(time1 / time2)
--msg("")
--msg(time2)
--msg(time2 / time1)








--local startTime = 0
--local function test1(test1,test2,test3,test4,test5,test6,test7,test8,test9)
--    local test = test1
--    test = test2
--    test = test3
--    test = test4
--    test = test5
--    test = test6
--    test = test7
--    test = test8
--    test = test9
--end
--local function test2(input)
--    local test = input.test1
--    test = input.test2
--    test = input.test3
--    test = input.test4
--    test = input.test5
--    test = input.test6
--    test = input.test7
--    test = input.test8
--    test = input.test9
--end
--
--
--startTime = reaper.time_precise()
--for i = 1, 100000 do
--    test1(1,2,3,4,5,6,7,8,9)
--end
--local time1 = reaper.time_precise() - startTime
--
--
--startTime = reaper.time_precise()
--for i = 1, 100000 do
--    test2{test1=1,test2=2,test3=3,test4=4,test5=5,test6=6,test7=7,test8=8,test9=9}
--end
--local time2 = reaper.time_precise() - startTime
--
--msg(time1)
--msg(time1 / time2)
--msg("")
--msg(time2)
--msg(time2 / time1)