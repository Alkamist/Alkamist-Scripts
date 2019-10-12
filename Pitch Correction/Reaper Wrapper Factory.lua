package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"

local ReaperTypes = {}
ReaperTypes.ReaperProject = require "Pitch Correction.Reaper Wrappers.ReaperProject"
ReaperTypes.ReaperTrack = require "Pitch Correction.Reaper Wrappers.ReaperTrack"
ReaperTypes.ReaperSend = require "Pitch Correction.Reaper Wrappers.ReaperSend"
ReaperTypes.ReaperEnvelope = require "Pitch Correction.Reaper Wrappers.ReaperEnvelope"
ReaperTypes.ReaperAutomationItem = require "Pitch Correction.Reaper Wrappers.ReaperAutomationItem"
ReaperTypes.ReaperItem = require "Pitch Correction.Reaper Wrappers.ReaperItem"
ReaperTypes.ReaperTake = require "Pitch Correction.Reaper Wrappers.ReaperTake"
ReaperTypes.ReaperStretchMarker = require "Pitch Correction.Reaper Wrappers.ReaperStretchMarker"
ReaperTypes.ReaperPCMSource = require "Pitch Correction.Reaper Wrappers.ReaperPCMSource"

local ReaperWrapperFactory = {}

ReaperWrapperFactory.createNew = function(baseTypeName, pointerOrIndex)
    -- These are things stored in Reaper as pointers.
    if baseTypeName == "ReaperProject"
    or baseTypeName == "ReaperTrack"
    or baseTypeName == "ReaperEnvelope"
    or baseTypeName == "ReaperItem"
    or baseTypeName == "ReaperTake"
    or baseTypeName == "ReaperPCMSource" then
        return ReaperTypes[baseTypeName]:new{
            pointer = pointerOrIndex,
            factory = ReaperWrapperFactory
        }
    end

    -- These are things stored in Reaper as indexes.
    if baseTypeName == "ReaperSend"
    or baseTypeName == "ReaperAutomationItem"
    or baseTypeName == "ReaperStretchMarker" then
        return ReaperTypes[baseTypeName]:new{
            index = pointerOrIndex,
            factory = ReaperWrapperFactory
        }
    end

    return nil
end

return ReaperWrapperFactory