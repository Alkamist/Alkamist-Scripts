package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

function msg(m) reaper.ShowConsoleMsg(tostring(m).."\n") end

local Project = require "API.Reaper Wrappers.Project"

local function getProjectPointerByNumber(projectNumber)
    local projectNumber = projectNumber or 0
    local pointer = reaper.EnumProjects(projectNumber - 1, "")
    return pointer
end

local function AlkamistAPI()
    local alk = {}

    -- Private Members:

    local _uiRefreshIsEnabled = true
    local _projectWrappers = {}
    local _projectsTable = setmetatable({}, {
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

    local function getProjectWrapperByNumber(projectNumber)
        local projectPointer = getProjectPointerByNumber(projectNumber)
        local projectString = tostring(projectPointer)
        _projectWrappers[projectString] = _projectWrappers[projectString] or Project(projectPointer)
        return _projectWrappers[projectString]
    end

    -- Object Oriented API Interface:

    function alk:getProject(projectNumber)        return getProjectWrapperByNumber(projectNumber) end
    function alk:getProjects()                    return projectsTable end
    function alk:getItems(projectNumber)          return getProjectWrapperByNumber(projectNumber):getItems() end
    function alk:getSelectedItems(projectNumber)  return getProjectWrapperByNumber(projectNumber):getSelectedItems() end
    function alk:getTracks(projectNumber)         return getProjectWrapperByNumber(projectNumber):getTracks() end
    function alk:getSelectedTracks(projectNumber) return getProjectWrapperByNumber(projectNumber):getSelectedTracks() end

    -- Reaper Functions:

    function alk:updateArrange() reaper.UpdateArrange() end
    function alk:setUIRefresh(enable)
        -- Enable UI refresh.
        if enable then
            if not _uiRefreshIsEnabled then
                reaper.PreventUIRefresh(-1)
                _uiRefreshIsEnabled = true
            end

        -- Disable UI refresh.
        else
            if _uiRefreshIsEnabled then
                reaper.PreventUIRefresh(1)
                _uiRefreshIsEnabled = false
            end
        end
    end
    function alk:getEELCommandID(name)
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

    -- Helpful Lua Functions:

    function alk:stringLines(str)
        return str:gmatch("[^\n]+")
    end
    function alk:invertTable(tbl)
        local invertedTable = {}
        for key, value in pairs(tbl) do
            invertedTable[value] = key
        end
        return invertedTable
    end
    function alk:round(number, places)
        if not places then
            return number > 0 and math.floor(number + 0.5) or math.ceil(number - 0.5)
        else
            places = 10 ^ places
            return number > 0 and math.floor(number * places + 0.5)
                              or math.ceil(number * places - 0.5) / places
        end
    end
    function alk:copyTable(source, base)
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

    return alk
end

return AlkamistAPI