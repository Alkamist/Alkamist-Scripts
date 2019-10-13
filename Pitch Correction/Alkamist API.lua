package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Factory = require "Pitch Correction.Reaper Wrapper Factory"

local AlkAPI = {}

-- Project can be omitted for current project.
function AlkAPI.wrap(pointer, project)
    return Factory.createNew(pointer, project)
end

-- 0 for current project.
function AlkAPI.getProject(projectNumber)
    if projectNumber == nil then projectNumber = 0 end
    local projectPointer, projectFilename = reaper.EnumProjects(projectNumber - 1, "")
    return AlkAPI.wrap(projectPointer)
end

function AlkAPI.getItem(itemNumber, projectNumber)
    return AlkAPI.getProject(projectNumber):getItem(itemNumber)
end

function AlkAPI.getItems(projectNumber)
    return AlkAPI.getProject(projectNumber).items
end

function AlkAPI.getSelectedItem(itemNumber, projectNumber)
    return AlkAPI.getProject(projectNumber):getSelectedItem(itemNumber)
end

function AlkAPI.getSelectedItems(projectNumber)
    return AlkAPI.getProject(projectNumber).selectedItems
end

function AlkAPI.getTrack(trackNumber, projectNumber)
    return AlkAPI.getProject(projectNumber):getTrack(trackNumber)
end

function AlkAPI.getTracks(projectNumber)
    return AlkAPI.getProject(projectNumber).tracks
end

function AlkAPI.getSelectedTrack(trackNumber, projectNumber)
    return AlkAPI.getProject(projectNumber):getSelectedTrack(trackNumber)
end

function AlkAPI.getSelectedTracks(projectNumber)
    return AlkAPI.getProject(projectNumber).selectedTracks
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