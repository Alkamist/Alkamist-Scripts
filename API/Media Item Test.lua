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

--msg(#Alk.items)
--msg(#Alk.selectedItems)
--msg(#Alk.tracks)
--msg(#Alk.selectedTracks)



--for _, item in ipairs(Alk.items) do
--    for _, take in ipairs(item.takes) do
--        msg(take.playrate)
--    end
--end





--local startTime = reaper.time_precise()
--local cumulativeTime1 = 0
--for _, item in ipairs(Alk.items) do
--    local startTime = reaper.time_precise()
--    local test1 = item.length
--    test1 = item.leftEdge
--    test1 = item.rightEdge
--    test1 = item.loops
--    test1 = item.activeTake
--    test1 = item.track.number
--    cumulativeTime1 = cumulativeTime1 + reaper.time_precise() - startTime
--end
--local time1 = reaper.time_precise() - startTime
--
--local cumulativeTime2 = 0
--startTime = reaper.time_precise()
--for i = 1, reaper.CountMediaItems(0) do
--    local item = reaper.GetMediaItem(0, i - 1)
--    local startTime = reaper.time_precise()
--    local test1 = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
--    test1 = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
--    test1 = test1 + test1
--    test1 = reaper.GetMediaItemInfo_Value(item, "B_LOOPSRC") > 0
--    test1 = reaper.GetActiveTake(item)
--    test1 = reaper.GetMediaTrackInfo_Value(reaper.GetMediaItemTrack(item), "IP_TRACKNUMBER")
--    cumulativeTime2 = cumulativeTime2 + reaper.time_precise() - startTime
--end
--local time2 = reaper.time_precise() - startTime
--
--msg(time1)
--msg(time2)
--msg(time1 / time2)
--msg(cumulativeTime1)
--msg(cumulativeTime2)
--msg(cumulativeTime1 / cumulativeTime2)


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


