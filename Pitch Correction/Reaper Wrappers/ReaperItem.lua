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
        if key == "activeTake" then return tbl.factory.createNew(reaper.GetActiveTake(tbl.pointer)) end
        if key == "track" then return tbl.factory.createNew(reaper.GetMediaItemTrack(tbl.pointer)) end
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

function ReaperItem.getCount(projectNumber)
    return reaper.CountMediaItems(projectNumber - 1)
end

function ReaperItem.getSelectedCount(projectNumber)
    return reaper.CountSelectedMediaItems(projectNumber - 1)
end

function ReaperItem.getFromNumber(number, projectNumber)
    return ReaperItem.factory.createNew(reaper.GetMediaItem(projectNumber - 1, number - 1))
end

function ReaperItem.getFromSelectedNumber(number, projectNumber)
    return ReaperItem.factory.createNew(reaper.GetSelectedMediaItem(projectNumber - 1, number - 1))
end

function ReaperItem.getAll(projectNumber)
    local output = {}
    for index = 1, ReaperItem.getCount(projectNumber) do
        table.insert(output, ReaperItem.getFromNumber(index, projectNumber))
    end
    return output
end

function ReaperItem.getSelected(projectNumber)
    local output = {}
    for index = 1, ReaperItem.getSelectedCount(projectNumber) do
        table.insert(output, ReaperItem.getFromSelectedNumber(index, projectNumber))
    end
    return output
end

return ReaperItem