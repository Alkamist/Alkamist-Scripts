package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Factory = require "API.Reaper Wrappers.Reaper Wrapper Factory"

local Alk = {}

-- Project can be omitted for current project.
function Alk.wrap(pointer, project)
    return Factory.createNew(pointer, project)
end

-- 0 for current project.
function Alk.getProject(projectNumber)
    if projectNumber == nil then projectNumber = 0 end
    local projectPointer, projectFilename = reaper.EnumProjects(projectNumber - 1, "")
    return Alk.wrap(projectPointer)
end

function Alk.getItem(itemNumber, projectNumber)
    return Alk.getProject(projectNumber):getItem(itemNumber)
end

function Alk.getItems(projectNumber)
    return Alk.getProject(projectNumber).items
end

function Alk.getSelectedItem(itemNumber, projectNumber)
    return Alk.getProject(projectNumber):getSelectedItem(itemNumber)
end

function Alk.getSelectedItems(projectNumber)
    return Alk.getProject(projectNumber).selectedItems
end

function Alk.getTrack(trackNumber, projectNumber)
    return Alk.getProject(projectNumber):getTrack(trackNumber)
end

function Alk.getTracks(projectNumber)
    return Alk.getProject(projectNumber).tracks
end

function Alk.getSelectedTrack(trackNumber, projectNumber)
    return Alk.getProject(projectNumber):getSelectedTrack(trackNumber)
end

function Alk.getSelectedTracks(projectNumber)
    return Alk.getProject(projectNumber).selectedTracks
end

--------------------- General API ---------------------

function Alk.mainCommand(id)
    if type(id) == "string" then
        reaper.Main_OnCommand(reaper.NamedCommandLookup(id), 0)
        return
    end
    reaper.Main_OnCommand(id, 0)
end

function Alk.getEELCommandID(name)
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
function Alk.setUIRefresh(enable)
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

function Alk.updateArrange()
    reaper.UpdateArrange()
end

return Alk