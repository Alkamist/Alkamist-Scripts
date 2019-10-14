package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local WrapperTypes = require "API.Reaper Wrappers.WrapperTypes"

local ReaperWrapperFactory = { types = WrapperTypes }
for _, type in pairs(ReaperWrapperFactory.types) do
    type.factory = ReaperWrapperFactory
end

local storedWrappers = {}

local function wrapPointer(pointer, projectWrapper, wrapperType)
    local projectStr = tostring(projectWrapper.pointer)
    local typeStr = tostring(wrapperType)
    local pointerStr = tostring(pointer)
    if storedWrappers[projectStr][typeStr] == nil then storedWrappers[projectStr][typeStr] = {} end
    if storedWrappers[projectStr][typeStr][pointerStr] == nil then
        storedWrappers[projectStr][typeStr][pointerStr] = wrapperType:new{
            pointer = pointer,
            project = projectWrapper
        }
    end
    return storedWrappers[projectStr][typeStr][pointerStr]
end

function ReaperWrapperFactory.createNew(pointer, projectWrapper)
    if reaper.ValidatePtr(pointer, "ReaProject*") then
        local projectStr = tostring(pointer)
        if storedWrappers[projectStr] == nil then
            storedWrappers[projectStr] = {
                ReaperProject = WrapperTypes.ReaperProject:new{ pointer = pointer }
            }
        end
        return storedWrappers[projectStr].ReaperProject
    end
    if projectWrapper then
        for _, wrapperType in pairs(ReaperWrapperFactory.types) do
            if projectWrapper:validatePointer(pointer, wrapperType.pointerType) then
                return wrapPointer(pointer, projectWrapper, wrapperType)
            end
        end
    end
    return nil
end

--function ReaperWrapperFactory.removePointer(pointer)
--    for _, wrapperType in pairs(ReaperWrapperFactory.types) do
--        if storedWrappers[tostring(pointer)] ~= nil then
--            storedWrappers[tostring(pointer)] = nil
--        end
--    end
--end

return ReaperWrapperFactory