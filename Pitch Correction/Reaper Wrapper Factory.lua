package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"

local WrapperTypes = {}
WrapperTypes.ReaperProject = require "Pitch Correction.Reaper Wrappers.ReaperProject"
WrapperTypes.ReaperTrack = require "Pitch Correction.Reaper Wrappers.ReaperTrack"
WrapperTypes.ReaperEnvelope = require "Pitch Correction.Reaper Wrappers.ReaperEnvelope"
WrapperTypes.ReaperItem = require "Pitch Correction.Reaper Wrappers.ReaperItem"
WrapperTypes.ReaperTake = require "Pitch Correction.Reaper Wrappers.ReaperTake"
WrapperTypes.ReaperPCMSource = require "Pitch Correction.Reaper Wrappers.ReaperPCMSource"

local ReaperWrapperFactory = {}

ReaperWrapperFactory.createNew = function(pointer, projectNumber)
    if projectNumber == nil then projectNumber = 1 end
    for _, wrapperType in pairs(WrapperTypes) do
        if wrapperType.isValid(pointer, projectNumber) then
            return wrapperType:new{
                pointer = pointer,
                factory = ReaperWrapperFactory
            }
        end
    end
    return nil
end

return ReaperWrapperFactory