package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Factory = require "API.Reaper Wrappers.ReaperWrapperFactory"

local Alk = {}
setmetatable(Alk, Alk)

-- 0 for current project.
local function getProject(projectNumber)
    if projectNumber == nil then projectNumber = 0 end
    local projectPointer = reaper.EnumProjects(projectNumber - 1, "")
    return Factory.createNew(projectPointer)
end

Alk.__index = function(tbl, key)
    if key == "projects" then
        return setmetatable({}, {
            __index = function(tbl, key)
                return getProject(key)
            end,
            __len = function(tbl)
                local numProjects = 0
                for _ in ipairs(Alk.projects) do
                    numProjects = numProjects + 1
                end
                return numProjects
            end
        })
    end

    if key == "items" then
        return Alk.projects[0].items
    end

    if key == "selectedItems" then
        return Alk.projects[0].selectedItems
    end

    if key == "tracks" then
        return Alk.projects[0].tracks
    end

    if key == "selectedTracks" then
        return Alk.projects[0].selectedTracks
    end
end

--------------------- General API ---------------------

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