function msg(m)
    reaper.ShowConsoleMsg(tostring(m).."\n")
end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Alk = require "API.Alkamist API"

--Alk.selectedItems[1].activeTake.pitchEnvelope.isVisible = false
--msg(Alk.items[2].length)
--msg(Alk.projects[0])
--msg(Alk.projects[2])
--msg(Alk.projects[1])
--msg(Alk.projects[2])
--
--for _, project in ipairs(Alk.projects) do
--    msg(#project.items)
--end

msg(#Alk.items)
msg(#Alk.selectedItems)
msg(#Alk.tracks)
msg(#Alk.selectedTracks)

--insideTime = 0
local startTime = reaper.time_precise()
for _, item in ipairs(Alk.items) do
    --local test1 = item.length
    --local test2 = item.leftEdge
    --local test3 = item.rightEdge
    --local test4 = item.loops
    --local test5 = item.activeTake
    --local test6 = item.track.number
end
local time1 = reaper.time_precise() - startTime

--msg(insideTime)
--msg(insideTime / time1)

startTime = reaper.time_precise()
for i = 1, reaper.CountMediaItems(0) do
    local item = reaper.GetMediaItem(0, i - 1)
    --local test1 = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    --local test2 = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    --local test3 = test1 + test2
    --local test4 = reaper.GetMediaItemInfo_Value(item, "B_LOOPSRC") > 0
    --local test5 = reaper.GetActiveTake(item)
    --local test6 = reaper.GetMediaTrackInfo_Value(reaper.GetMediaItemTrack(item), "IP_TRACKNUMBER")
end
local time2 = reaper.time_precise() - startTime

msg(time1)
msg(time2)
msg(time1 / time2)

--for _, item in ipairs(Alk.selectedItems) do
--    msg(item.length)
--    msg(item.leftEdge)
--    msg(item.rightEdge)
--    msg(item.loops)
--    msg(item.activeTake)
--end
--
--for _, track in ipairs(Alk.selectedTracks) do
--    msg(track.number)
--end


--msg(proj:isValid())
--msg(proj.name)
--Alk.getProject(0).name = 5
--msg(proj.name)
--msg(proj.itemCount)
--msg(proj.items)
--msg(proj.selectedItemCount)
--msg(proj.selectedItems)
--msg(proj.trackCount)
--msg(proj.tracks)
--msg(proj.selectedTrackCount)
--msg(proj.selectedTracks)
--msg("")
--
--local items = Alk.getItems()
--for _, item in ipairs(items) do
--    item.length = 20
--    item.leftEdge = 5
--    msg(item.length)
--    msg(item.leftEdge)
--    msg(item.rightEdge)
--    msg(item.loops)
--    msg(item.activeTake)
--    msg(item.track.number)
--end

--msg(Alk.getItem(1))
--msg(Alk.getSelectedItem(3))
--msg(Alk.getSelectedItem(3))
--msg(Alk.getSelectedItem(3))
--msg(Alk.getSelectedItem(3))
--
--msg(Alk.getTrack(1))
--msg(Alk.getSelectedTrack(3))
--msg(Alk.getSelectedTrack(3))
--msg(Alk.getSelectedTrack(3))
--msg(Alk.getSelectedTrack(3))
--
--
--local tracks = Alk.getTracks()
--for _, track in ipairs(tracks) do
--    msg(track.project)
--    msg(track.number)
--end


