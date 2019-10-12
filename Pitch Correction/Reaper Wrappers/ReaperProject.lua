package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"

local ReaperProject = {
    pointerType = "ReaProject*"
}

local ReaperProject_mt = {

    -- Getters
    __index = function(tbl, key)
        return ReaperProject[key]
    end,

    -- Setters
    __newindex = function(tbl, key, value)
        rawset(tbl, key, value)
    end

}

function ReaperProject:new(object)
    local object = object or {}
    setmetatable(object, ReaperProject_mt)
    return object
end

return ReaperProject