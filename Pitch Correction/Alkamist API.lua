package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"
local factory = require "Pitch Correction.Reaper Wrapper Factory"

local AlkAPI = {}

function AlkAPI.wrapProject(projectNumber)
end
function AlkAPI.getProjects()
end

function AlkAPI.wrapItem(pointer)
    if AlkWrap.isItem(pointer) then
        return factory.createNew("ReaperItem", pointer)
    end
    return nil
end
function AlkAPI.getItems(projectNumber)
    if projectNumber == nil then projectNumber = 1 end
    local items = {}
    for index = 1, AlkWrap.getNumItems(projectNumber) do
        table.insert(items, AlkAPI.wrapItem(AlkWrap.getItem(projectNumber, index)))
    end
    return items
end
function AlkAPI.getSelectedItems(projectNumber)
    if projectNumber == nil then projectNumber = 1 end
    local items = {}
    for index = 1, AlkWrap.getNumSelectedItems(projectNumber) do
        table.insert(items, AlkAPI.wrapItem(AlkWrap.getSelectedItem(projectNumber, index)))
    end
    return items
end

function AlkAPI.wrapTrack(pointer)
    if AlkWrap.isTrack(pointer) then
        return factory.createNew("ReaperTrack", pointer)
    end
    return nil
end
function AlkAPI.getTracks(projectNumber)
    if projectNumber == nil then projectNumber = 1 end
    local tracks = {}
    for index = 1, AlkWrap.getNumTracks(projectNumber) do
        table.insert(tracks, AlkAPI.wrapTrack(AlkWrap.getTrack(projectNumber, index)))
    end
    return tracks
end
function AlkAPI.getSelectedTracks(projectNumber)
    if projectNumber == nil then projectNumber = 1 end
    local tracks = {}
    for index = 1, AlkWrap.getNumSelectedTracks(projectNumber) do
        table.insert(tracks, AlkAPI.wrapTrack(AlkWrap.getSelectedTrack(projectNumber, index)))
    end
    return tracks
end

return AlkAPI