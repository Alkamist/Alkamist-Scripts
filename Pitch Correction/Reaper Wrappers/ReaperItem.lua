package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"

local ReaperItem = {
    pointerType = "MediaItem*"
}

local ReaperItem_mt = {

    -- Getters
    __index = function(tbl, key)
        if key == "length" then return AlkWrap.getItemLength(tbl.pointer) end
        if key == "leftEdge" then return AlkWrap.getItemLeftEdge(tbl.pointer) end
        if key == "rightEdge" then return AlkWrap.getItemRightEdge(tbl.pointer) end
        if key == "loops" then return AlkWrap.getItemLoops(tbl.pointer) end
        if key == "activeTake" then return tbl.factory.createNew("ReaperTake", AlkWrap.getItemActiveTake(tbl.pointer)) end
        if key == "track" then return tbl.factory.createNew("ReaperTrack", AlkWrap.getItemTrack(tbl.pointer)) end
        return ReaperItem[key]
    end,

    -- Setters
    __newindex = function(tbl, key, value)
        if key == "length" then return AlkWrap.setItemLength(tbl.pointer, value) end
        if key == "leftEdge" then return AlkWrap.setItemLeftEdge(tbl.pointer, value) end
        if key == "rightEdge" then return AlkWrap.setItemRightEdge(tbl.pointer, value) end
        if key == "loops" then return AlkWrap.setItemLoops(tbl.pointer, value) end
        rawset(tbl, key, value)
    end

}

function ReaperItem:new(object)
    local object = object or {}
    setmetatable(object, ReaperItem_mt)
    return object
end

return ReaperItem