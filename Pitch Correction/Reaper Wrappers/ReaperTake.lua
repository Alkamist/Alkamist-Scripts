package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"

local ReaperTake = {
    pointerType = "MediaItem_Take*"
}

local ReaperTake_mt = {

    -- Getters
    __index = function(tbl, key)
        if key == "name" then return AlkWrap.getTakeName(tbl.pointer) end
        if key == "type" then return AlkWrap.getTakeType(tbl.pointer) end
        if key == "GUID" then return AlkWrap.getTakeGUID(tbl.pointer) end
        if key == "item" then return tbl.factory.createNew("ReaperItem", AlkWrap.getTakeItem(tbl.pointer)) end
        return ReaperTake[key]
    end,

    -- Setters
    __newindex = function(tbl, key, value)
        if key == "name" then return AlkWrap.setTakeName(tbl.pointer, value) end
        rawset(tbl, key, value)
    end

}

function ReaperTake:new(object)
    local object = object or {}
    setmetatable(object, ReaperTake_mt)
    return object
end

return ReaperTake