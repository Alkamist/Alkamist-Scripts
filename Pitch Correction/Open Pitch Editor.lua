package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local PitchCorrection = require "Pitch Correction.Classes.Class - PitchCorrection"

require "Pitch Correction.GUI.Pitch Editor GUI"