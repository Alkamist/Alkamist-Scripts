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

--------------------- General API ---------------------

function AlkAPI.mainCommand(id)
    if type(id) == "string" then
        reaper.Main_OnCommand(reaper.NamedCommandLookup(id), 0)
        return
    end
    reaper.Main_OnCommand(id, 0)
end

function AlkAPI.getEELCommandID(name)
    local kbini = reaper.GetResourcePath() .. '/reaper-kb.ini'
    local file = io.open(kbini, 'r')

    local content = nil
    if file then
        content = file:read('a')
        file:close()
    end

    if content then
        local nameString = nil
        for line in content:gmatch('[^\r\n]+') do
            if line:match(name) then
                nameString = line:match('SCR %d+ %d+ ([%a%_%d]+)')
                break
            end
        end

        local commandID = nil
        if nameString then
            commandID = reaper.NamedCommandLookup('_' .. nameString)
        end

        if commandID and commandID ~= 0 then
            return commandID
        end
    end

    reaper.MB(name .. " not found!", "Error!", 0)
    return nil
end

local uiEnabled = true
function AlkAPI.setUIRefresh(enable)
    -- Enable UI refresh.
    if enable then
        if not uiEnabled then
            reaper.PreventUIRefresh(-1)
            uiEnabled = true
        end

    -- Disable UI refresh.
    else
        if uiEnabled then
            reaper.PreventUIRefresh(1)
            uiEnabled = false
        end
    end
end

function AlkAPI.updateArrange()
    reaper.UpdateArrange()
end

return AlkAPI