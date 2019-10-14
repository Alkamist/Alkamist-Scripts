package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local WrapperTypes = require "API.Reaper Wrappers.WrapperTypes"

local ReaperWrapperFactory = { types = WrapperTypes }
for _, type in pairs(ReaperWrapperFactory.types) do
    type.factory = ReaperWrapperFactory
end

local wrapperStorageList = {}

function ReaperWrapperFactory.createNew(pointer, project)
    if pointer == nil then return nil end
    if project == nil then project = reaper.EnumProjects(-1, "") end
    for _, wrapperType in pairs(ReaperWrapperFactory.types) do
        if reaper.ValidatePtr2(project, pointer, wrapperType.pointerType) then
            if wrapperStorageList[tostring(pointer)] == nil then
                wrapperStorageList[tostring(pointer)] = wrapperType:new{
                    pointer = pointer,
                    project = project
                }
            end
            return wrapperStorageList[tostring(pointer)]
        end
    end
    return nil
end

function ReaperWrapperFactory.removePointer(pointer)
    for _, wrapperType in pairs(ReaperWrapperFactory.types) do
        if wrapperStorageList[tostring(pointer)] ~= nil then
            wrapperStorageList[tostring(pointer)] = nil
        end
    end
end

return ReaperWrapperFactory