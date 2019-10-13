package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"

local ReaperPCMSource = {
    pointerType = "ReaProject*"
}

local ReaperPCMSource_mt = {

    -- Getters
    __index = function(tbl, key)
        return ReaperPCMSource[key]
    end,

    -- Setters
    __newindex = function(tbl, key, value)
        rawset(tbl, key, value)
    end

}

function ReaperPCMSource:new(object)
    local object = object or {}
    setmetatable(object, ReaperPCMSource_mt)
    return object
end

function ReaperPCMSource.isValid(pointer, projectNumber)
    return pointer ~= nil and reaper.ValidatePtr2(projectNumber - 1, pointer, ReaperPCMSource.pointerType)
end

return ReaperPCMSource