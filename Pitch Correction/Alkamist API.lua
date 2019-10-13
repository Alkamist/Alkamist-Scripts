package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Factory = require "Pitch Correction.Reaper Wrapper Factory"

local AlkAPI = {}

-- Project number can be omitted for current project.
function AlkAPI.wrap(pointer, projectNumber)
    return Factory.createNew(pointer, projectNumber)
end

function AlkAPI.get(typeToGet, typeNumber, projectNumber)
    if projectNumber == nil then projectNumber = 1 end
    if typeToGet == "items"          then return Factory.types.ReaperItem.getAll(projectNumber) end
    if typeToGet == "selectedItems"  then return Factory.types.ReaperItem.getSelected(projectNumber) end
    if typeToGet == "tracks"         then return Factory.types.ReaperTrack.getAll(projectNumber) end
    if typeToGet == "selectedTracks" then return Factory.types.ReaperTrack.getSelected(projectNumber) end

    if typeToGet == "item"           then return Factory.types.ReaperItem.getFromNumber(typeNumber, projectNumber) end
    if typeToGet == "selectedItem"   then return Factory.types.ReaperItem.getFromSelectedNumber(typeNumber, projectNumber) end
    if typeToGet == "track"          then return Factory.types.ReaperTrack.getFromNumber(typeNumber, projectNumber) end
    if typeToGet == "selectedTrack"  then return Factory.types.ReaperTrack.getFromSelectedNumber(typeNumber, projectNumber) end

    if typeToGet == "project"        then return Factory.types.ReaperProject.getFromNumber(typeNumber, projectNumber) end
    if typeToGet == "projects"       then return Factory.types.ReaperProject.getAll(typeNumber, projectNumber) end
    return nil
end

return AlkAPI