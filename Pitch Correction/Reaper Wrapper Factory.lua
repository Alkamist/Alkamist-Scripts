package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"

local WrapperTypes = {}
WrapperTypes.ReaperProject = require "Pitch Correction.Reaper Wrappers.ReaperProject"
WrapperTypes.ReaperTrack = require "Pitch Correction.Reaper Wrappers.ReaperTrack"
WrapperTypes.ReaperEnvelope = require "Pitch Correction.Reaper Wrappers.ReaperEnvelope"
WrapperTypes.ReaperItem = require "Pitch Correction.Reaper Wrappers.ReaperItem"
WrapperTypes.ReaperTake = require "Pitch Correction.Reaper Wrappers.ReaperTake"
WrapperTypes.ReaperPCMSource = require "Pitch Correction.Reaper Wrappers.ReaperPCMSource"

local ReaperWrapperFactory = {
    types = WrapperTypes
}

local wrapperStorageList = {}

for _, type in pairs(ReaperWrapperFactory.types) do
    type.factory = ReaperWrapperFactory
end

function ReaperWrapperFactory.createNew(pointer, projectNumber)
    if projectNumber == nil then projectNumber = 1 end
    for _, wrapperType in pairs(ReaperWrapperFactory.types) do
        if wrapperType.isValid(pointer, projectNumber) then
            if wrapperStorageList[tostring(pointer)] == nil then
                wrapperStorageList[tostring(pointer)] = wrapperType:new{ pointer = pointer }
            end
            return wrapperStorageList[tostring(pointer)]
        end
    end
    return nil
end

function ReaperWrapperFactory.removePointer(pointer, projectNumber)
    if projectNumber == nil then projectNumber = 1 end
    for _, wrapperType in pairs(ReaperWrapperFactory.types) do
        if wrapperStorageList[tostring(pointer)] ~= nil then
            wrapperStorageList[tostring(pointer)] = nil
        end
    end
end

return ReaperWrapperFactory