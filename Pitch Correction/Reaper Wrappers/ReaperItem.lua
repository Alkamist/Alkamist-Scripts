package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"

local ReaperItem = {
    pointerType = "MediaItem*"
}

local ReaperItem_mt = {

    -- Getters
    __index = function(tbl, key)
        if key == "length" then return reaper.GetMediaItemInfo_Value(tbl.pointer, "D_LENGTH") end
        if key == "leftEdge" then return reaper.GetMediaItemInfo_Value(tbl.pointer, "D_POSITION") end
        if key == "rightEdge" then return tbl.leftEdge + tbl.length end
        if key == "loops" then return reaper.GetMediaItemInfo_Value(tbl.pointer, "B_LOOPSRC") > 0 end
        if key == "activeTake" then return tbl.factory.createNew("ReaperTake", reaper.GetActiveTake(tbl.pointer)) end
        if key == "track" then return tbl.factory.createNew("ReaperTrack", reaper.GetMediaItemTrack(tbl.pointer)) end
        return ReaperItem[key]
    end,

    -- Setters
    __newindex = function(tbl, key, value)
        if key == "length" then reaper.SetMediaItemLength(tbl.pointer, value, false); return end
        if key == "leftEdge" then reaper.SetMediaItemPosition(tbl.pointer, value, false); return end
        if key == "rightEdge" then tbl.leftEdge = math.max(0.0, value - tbl.length); return end
        if key == "loops" then reaper.SetMediaItemInfo_Value(tbl.pointer, "B_LOOPSRC", value and 1 or 0); return end
        rawset(tbl, key, value)
    end

}

function ReaperItem:new(object)
    local object = object or {}
    setmetatable(object, ReaperItem_mt)
    return object
end

function ReaperItem.isValid(pointer, projectNumber)
    return pointer ~= nil and reaper.ValidatePtr2(projectNumber - 1, pointer, ReaperItem.pointerType)
end

return ReaperItem