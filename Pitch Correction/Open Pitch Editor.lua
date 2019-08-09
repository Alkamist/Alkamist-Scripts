package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local PitchCorrection = require "Classes.Class - PitchCorrection"

require "GUI.Pitch Editor GUI"