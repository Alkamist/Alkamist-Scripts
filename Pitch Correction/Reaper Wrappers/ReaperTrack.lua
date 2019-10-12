package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"

local ReaperTrack = {
    pointerType = "MediaTrack*"
}

local ReaperTrack_mt = {

    -- Getters
    __index = function(tbl, key)
        return ReaperTrack[key]
    end,

    -- Setters
    __newindex = function(tbl, key, value)
        rawset(tbl, key, value)
    end

}

function ReaperTrack:new(object)
    local object = object or {}
    setmetatable(object, ReaperTrack_mt)
    return object
end

return ReaperTrack