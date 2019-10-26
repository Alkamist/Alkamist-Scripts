local reaper = reaper

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

function msg(m) reaper.ShowConsoleMsg(tostring(m).."\n") end

local Project = require "API.Reaper Wrappers.Project"

local Alk = {}

Alk.uiRefreshIsEnabled = true
Alk.projectWrappers = {}

-- Object Oriented API Interface:

function Alk:getProjectPointerByNumber(projectNumber)
    if projectNumber == 0 then return 0 end
    local projectNumber = projectNumber or 0
    local pointer = reaper.EnumProjects(projectNumber - 1, "")
    return pointer
end
function Alk:getProject(projectNumber)
    local projectPointer = self:getProjectPointerByNumber(projectNumber)
    local projectString = tostring(projectPointer)
    self.projectWrappers[projectString] = self.projectWrappers[projectString] or Project:new(projectPointer)
    return self.projectWrappers[projectString]
end
function Alk:getProjects()
    return setmetatable({}, {
        __index = function(tbl, key)
            return self:getProject(key)
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
end
function Alk:getItems(projectNumber)          return self:getProject(projectNumber):getItems() end
function Alk:getSelectedItems(projectNumber)  return self:getProject(projectNumber):getSelectedItems() end
function Alk:getTracks(projectNumber)         return self:getProject(projectNumber):getTracks() end
function Alk:getSelectedTracks(projectNumber) return self:getProject(projectNumber):getSelectedTracks() end

-- Reaper Functions:

function Alk:updateArrange() reaper.UpdateArrange() end
function Alk:setUIRefresh(enable)
    -- Enable UI refresh.
    if enable then
        if not self.uiRefreshIsEnabled then
            reaper.PreventUIRefresh(-1)
            self.uiRefreshIsEnabled = true
        end

    -- Disable UI refresh.
    else
        if self.uiRefreshIsEnabled then
            reaper.PreventUIRefresh(1)
            self.uiRefreshIsEnabled = false
        end
    end
end
function Alk:getEELCommandID(name)
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

function Alk:stringLines(str)
    return str:gmatch("[^\n]+")
end
function Alk:invertTable(tbl)
    local invertedTable = {}
    for key, value in pairs(tbl) do
        invertedTable[value] = key
    end
    return invertedTable
end
function Alk:round(number, places)
    if not places then
        return number > 0 and math.floor(number + 0.5) or math.ceil(number - 0.5)
    else
        places = 10 ^ places
        return number > 0 and math.floor(number * places + 0.5)
                          or math.ceil(number * places - 0.5) / places
    end
end
function Alk:copyTable(source, base)
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