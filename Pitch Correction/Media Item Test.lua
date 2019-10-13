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

local AlkAPI = require "Pitch Correction.Alkamist API"

msg(AlkAPI.getProject(0).name)
--msg(AlkAPI.getProject(0).itemCount)
--msg(AlkAPI.getProject(0).selectedItemCount)

--local items = AlkAPI.getItems()
--for _, item in ipairs(items) do
--    --item.length = 20
--    msg(item.length)
--    msg(item.leftEdge)
--    msg(item.rightEdge)
--    msg(item.loops)
--    msg(item.activeTake)
--    msg(item.track.number)
--end

msg(AlkAPI.getItem(1))
msg(AlkAPI.getSelectedItem(3))
msg(AlkAPI.getSelectedItem(3))
msg(AlkAPI.getSelectedItem(3))
msg(AlkAPI.getSelectedItem(3))

msg(AlkAPI.getTrack(1))
msg(AlkAPI.getSelectedTrack(3))
msg(AlkAPI.getSelectedTrack(3))
msg(AlkAPI.getSelectedTrack(3))
msg(AlkAPI.getSelectedTrack(3))
--
--
--local tracks = AlkAPI.getTracks()
--for _, track in ipairs(tracks) do
--    msg(track.number)
--end


