package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"

local ReaperTrack = {
    pointerType = "MediaTrack*"
}

local ReaperTrack_mt = {

    -- Getters
    __index = function(tbl, key)
        if key == "number" then return reaper.GetMediaTrackInfo_Value(tbl.pointer, "IP_TRACKNUMBER") end
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

function ReaperTrack.isValid(pointer, projectNumber)
    return pointer ~= nil and reaper.ValidatePtr2(projectNumber - 1, pointer, ReaperTrack.pointerType)
end

function ReaperTrack.getCount(projectNumber)
    return reaper.CountTracks(projectNumber - 1)
end

function ReaperTrack.getSelectedCount(projectNumber)
    return reaper.CountSelectedTracks(projectNumber - 1)
end

function ReaperTrack.getFromNumber(number, projectNumber)
    return ReaperTrack.factory.createNew(reaper.GetTrack(projectNumber - 1, number - 1))
end

function ReaperTrack.getFromSelectedNumber(number, projectNumber)
    return ReaperTrack.factory.createNew(reaper.GetSelectedTrack(projectNumber - 1, number - 1))
end

function ReaperTrack.getAll(projectNumber)
    local output = {}
    for index = 1, ReaperTrack.getCount(projectNumber) do
        table.insert(output, ReaperTrack.getFromNumber(index, projectNumber))
    end
    return output
end

function ReaperTrack.getSelected(projectNumber)
    local output = {}
    for index = 1, ReaperTrack.getSelectedCount(projectNumber) do
        table.insert(output, ReaperTrack.getFromSelectedNumber(index, projectNumber))
    end
    return output
end

return ReaperTrack