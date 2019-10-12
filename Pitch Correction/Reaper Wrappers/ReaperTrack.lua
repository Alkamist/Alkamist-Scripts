package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"

local ReaperTrack = {
    pointerType = "MediaTrack*"
}

local ReaperTrack_mt = {

    -- Getters
    __index = function(tbl, key)
        if key == "length" then return AlkWrap.getItemLength(tbl.pointer) end
        return ReaperTrack[key]
    end,

    -- Setters
    __newindex = function(tbl, key, value)
        if key == "length" then return AlkWrap.setItemLength(tbl.pointer, value) end
        rawset(tbl, key, value)
    end

}

function ReaperTrack:new(object)
    local object = object or {}
    setmetatable(object, ReaperTrack_mt)
    return object
end

return ReaperTrack