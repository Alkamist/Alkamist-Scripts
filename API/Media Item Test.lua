function msg(m)
    reaper.ShowConsoleMsg(tostring(m).."\n")
end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
--local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"
--local ReaperItem = require "Pitch Correction.Reaper Wrappers.ReaperItem"
--
--local selectedMediaItems = AlkWrap.getSelectedItems(1)
--
--for _, item in ipairs(selectedMediaItems) do
--    local test = ReaperItem:new{ pointer = item }
--    local test2 = ReaperItem:new{ pointer = item }
--
--    msg("pointer: " .. tostring(test.pointer))
--    msg("pointerType: " .. tostring(test.pointerType))
--    msg("length: " .. tostring(test.length))
--    msg("leftEdge: " .. tostring(test.leftEdge))
--    msg("rightEdge: " .. tostring(test.rightEdge))
--    msg("loops: " .. tostring(test.loops))
--
--    test.length = 20.0
--    test.leftEdge = 1.0
--    test.rightEdge = 15.0
--    test.loops = true
--end

local Alk = require "API.Alkamist API"

Alk.getSelectedItem(1).activeTake.pitchEnvelope:hide()

--local test = Alk.getProject()
--msg(test:isValid())
--msg(test.name)
--Alk.getProject(0).name = 5
--msg(test.name)
--msg(test.itemCount)
--msg(test.items)
--msg(test.selectedItemCount)
--msg(test.selectedItems)
--msg(test.trackCount)
--msg(test.tracks)
--msg(test.selectedTrackCount)
--msg(test.selectedTracks)
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


