package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Track = require "Pitch Correction.Track"
local MediaItem = require "Pitch Correction.Media Item"
local MediaTake = require "Pitch Correction.Media Take"