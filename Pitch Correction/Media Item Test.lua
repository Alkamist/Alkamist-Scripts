function msg(m)
    reaper.ShowConsoleMsg(tostring(m).."\n")
end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local MediaItem = require "Pitch Correction.Media Item"

local test1 = MediaItem:newFromSelectedIndex(1)
msg("pointer: " .. tostring(test1.pointer))
msg("track: " .. tostring(test1:getTrack()))
msg("length: " .. tostring(test1:getLength()))
msg("leftTime: " .. tostring(test1:getLeftTime()))
msg("rightTime: " .. tostring(test1:getRightTime()))
msg("isEmpty: " .. tostring(test1:isEmpty()))

msg("")

local testTake1 = test1:getActiveTake()
msg("item: " .. tostring(testTake1:getItem()))
msg("type: " .. tostring(testTake1:getType()))
msg("name: " .. tostring(testTake1:getName()))
msg("GUID: " .. tostring(testTake1:getGUID()))
msg("source: " .. tostring(testTake1:getSource()))
msg("fileName: " .. tostring(testTake1:getFileName()))
msg("sourceLength: " .. tostring(testTake1:getSourceLength()))
msg("pitchEnvelope: " .. tostring(testTake1:getPitchEnvelope()))
msg("playrate: " .. tostring(testTake1:getPlayrate()))
msg("startOffset: " .. tostring(testTake1:getStartOffset()))