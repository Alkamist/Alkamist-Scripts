package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"

local ReaperTake = {
    pointerType = "MediaItem_Take*"
}

local ReaperTake_mt = {

    -- Getters
    __index = function(tbl, key)
        if key == "name" then return reaper.GetTakeName(tbl.pointer) end
        if key == "type" then return ReaperTake.getType(tbl.pointer) end
        if key == "GUID" then return reaper.BR_GetMediaItemTakeGUID(tbl.pointer) end
        if key == "item" then return tbl.factory.createNew("ReaperItem", reaper.GetMediaItemTake_Item(tbl.pointer)) end
        return ReaperTake[key]
    end,

    -- Setters
    __newindex = function(tbl, key, value)
        if key == "name" then reaper.GetSetMediaItemTakeInfo_String(tbl.pointer, "P_NAME", "", true); return end
        rawset(tbl, key, value)
    end

}

function ReaperTake:new(object)
    local object = object or {}
    setmetatable(object, ReaperTake_mt)
    return object
end

function ReaperTake.isValid(pointer, projectNumber)
    return pointer ~= nil and reaper.ValidatePtr2(projectNumber - 1, pointer, ReaperTake.pointerType)
end

function ReaperTake.getType(pointer)
    if reaper.TakeIsMIDI(pointer) then
        return "midi"
    end
    return "audio"
end

return ReaperTake