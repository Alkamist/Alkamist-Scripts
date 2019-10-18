package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

function msg(m) reaper.ShowConsoleMsg(tostring(m).."\n") end

local Project = require "API.Reaper Wrappers.Project"

local Alk = {}

--------------------- Object Oriented Wrapper ---------------------

local function getProjectPointerByNumber(projectNumber)
    local projectNumber = projectNumber or 0
    local pointer = reaper.EnumProjects(projectNumber - 1, "")
    return pointer
end
local function getProjectWrapperByNumber(projectNumber)
    return Project(getProjectPointerByNumber(projectNumber))
end

local projectsTable = setmetatable({}, {
    __index = function(tbl, key)
        return getProjectWrapperByNumber(key)
    end,
    __len = function(tbl)
        local numProjects = 0
        for _ in ipairs(tbl) do
            numProjects = numProjects + 1
        end
        return numProjects
    end,
    __pairs = function(tbl)
        return ipairs(tbl)
    end
})

function Alk.getProject(projectNumber)
    return getProjectWrapperByNumber(projectNumber)
end
function Alk.getProjects()
    return projectsTable
end
function Alk.getItems(projectNumber)
    return getProjectWrapperByNumber(projectNumber):getItems()
end
function Alk.getSelectedItems(projectNumber)
    return getProjectWrapperByNumber(projectNumber):getSelectedItems()
end
function Alk.getTracks(projectNumber)
    return getProjectWrapperByNumber(projectNumber):getTracks()
end
function Alk.getSelectedTracks(projectNumber)
    return getProjectWrapperByNumber(projectNumber):getSelectedTracks()
end

--------------------- Reaper Function Wrappers ---------------------

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

--------------------- Helpful Lua Functions ---------------------

function Alk.stringLines(str)
    return str:gmatch("[^\n]+")
end

function Alk.invertTable(tbl)
    local invertedTable = {}
    for key, value in pairs(tbl) do
        invertedTable[value] = key
    end
    return invertedTable
end

function Alk.round(number, places)
    if not places then
        return number > 0 and math.floor(number + 0.5) or math.ceil(number - 0.5)
    else
        places = 10 ^ places
        return number > 0 and math.floor(number * places + 0.5)
                          or math.ceil(number * places - 0.5) / places
    end
end

function Alk.copyTable(source, base)
    if type(source) ~= "table" then return source end
    local meta = getmetatable(source)
    local new = base or {}
    for k, v in pairs(source) do
        if type(v) == "table" then
            if base then
                new[k] = GUI.table_copy(v, base[k])
            else
                new[k] = GUI.table_copy(v, nil)
            end
        else
            if not base or (base and new[k] == nil) then
                new[k] = v
            end
        end
    end
    setmetatable(new, meta)
    return new
end

return Alk