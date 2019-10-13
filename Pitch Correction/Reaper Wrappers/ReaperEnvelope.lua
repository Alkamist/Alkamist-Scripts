package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"

local ReaperEnvelope = {
    pointerType = "ReaProject*"
}

local ReaperEnvelope_mt = {

    -- Getters
    __index = function(tbl, key)
        return ReaperEnvelope[key]
    end,

    -- Setters
    __newindex = function(tbl, key, value)
        rawset(tbl, key, value)
    end

}

function ReaperEnvelope:new(object)
    local object = object or {}
    setmetatable(object, ReaperEnvelope_mt)
    return object
end

function ReaperEnvelope.isValid(pointer, projectNumber)
    return pointer ~= nil and reaper.ValidatePtr2(projectNumber - 1, pointer, ReaperEnvelope.pointerType)
end

return ReaperEnvelope