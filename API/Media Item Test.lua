function msg(m)
    reaper.ShowConsoleMsg(tostring(m).."\n")
end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Alk = require "API.Alkamist API"

--Alk.selectedItems[1].activeTake.pitchEnvelope.isVisible = true

for _, item in ipairs(Alk.items) do
    msg(item.length)
    msg(item.leftEdge)
    msg(item.rightEdge)
    msg(item.loops)
    msg(item.activeTake)
    msg(item.track.number)
end

for _, item in ipairs(Alk.selectedItems) do
    msg(item.length)
    msg(item.leftEdge)
    msg(item.rightEdge)
    msg(item.loops)
    msg(item.activeTake)
end

for _, track in ipairs(Alk.selectedTracks) do
    msg(track.number)
end


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


