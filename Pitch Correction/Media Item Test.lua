function msg(m)
    reaper.ShowConsoleMsg(tostring(m).."\n")
end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"
local MediaItem = require "Pitch Correction.Media Item"

local selectedMediaItems = AlkWrap.getSelectedMediaItems(1)
for _, item in ipairs(selectedMediaItems) do
    local test = MediaItem:new{ pointer = item }

    msg("pointer: " .. tostring(test.pointer))
    msg("pointerType: " .. tostring(test.pointerType))
    msg("length: " .. tostring(test.length))
    msg("leftEdge: " .. tostring(test.leftEdge))
    msg("rightEdge: " .. tostring(test.rightEdge))
    msg("loops: " .. tostring(test.loops))

    --test.length = 20.0
    --test.leftEdge = 1.0
    --test.rightEdge = 3.0
    --test.loops = true
end

--local test1 = selectedMediaItems[1]

--msg("pointer: " .. tostring(test1.pointer))
--msg("track: " .. tostring(test1:getTrack()))
--msg("length: " .. tostring(test1:getLength()))
--msg("leftTime: " .. tostring(test1:getLeftTime()))
--msg("rightTime: " .. tostring(test1:getRightTime()))
--msg("isEmpty: " .. tostring(test1:isEmpty()))
--msg("name: " .. tostring(test1:getName()))
--
--msg("")
--
--local testTake1 = test1:getActiveTake()
--msg("item: " .. tostring(testTake1:getItem()))
--msg("type: " .. tostring(testTake1:getType()))
--msg("name: " .. tostring(testTake1:getName()))
--msg("GUID: " .. tostring(testTake1:getGUID()))
--msg("source: " .. tostring(testTake1:getSource()))
--msg("fileName: " .. tostring(testTake1:getFileName()))
--msg("sourceLength: " .. tostring(testTake1:getSourceLength()))
--msg("pitchEnvelope: " .. tostring(testTake1:getPitchEnvelope()))
--msg("playrate: " .. tostring(testTake1:getPlayrate()))
--msg("startOffset: " .. tostring(testTake1:getStartOffset()))

--local currentProject = Rpr.project(0)
--
--for index, item in ipairs(currentProject.selectedItems) do
--    item.pitch = 24.0 * math.random() - 12.0
--end

--local numSelectedItems = reaper.CountSelectedMediaItems(0)
--local selectedItems = {}
--for i = 1, numSelectedItems do
--    table.insert(selectedItems, reaper.GetSelectedMediaItem(0, i - 1))
--end
--local t0 = reaper.time_precise()
--local asdf = selectedItems
--local t1 = reaper.time_precise()
--msg("old skool write access took " .. t1 - t0 .. "\n")