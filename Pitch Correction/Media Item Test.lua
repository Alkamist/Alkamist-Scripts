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

msg("")

local testTake1 = test1:getActiveTake()
msg("item: " .. tostring(testTake1:getItem()))
msg("type: " .. tostring(testTake1:getType()))