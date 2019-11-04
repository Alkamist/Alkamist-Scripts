local setmetatable = setmetatable
local rawget = rawget

local function copyTable(input, seen)
    if type(input) ~= "table" then return input end
    local seen = seen or {}
    if seen[input] then return seen[input] end
    local output = {}
    seen[input] = output
    for key, value in next, input, nil do
        output[copyTable(key, seen)] = copyTable(value, seen)
    end
    return setmetatable(output, getmetatable(input))
end
local function tableAlreadyHasPrototype(inputTable, prototype)
    local tablePrototypes = inputTable._prototypes
    if tablePrototypes == nil then return false end
    for i = 1, #tablePrototypes do
        local tablePrototype = tablePrototypes[i]
        if tablePrototype == prototype then return true end
    end
    return false
end
local function initializeTableWithRespectToPrototype(inputTable, prototype)
    if not tableAlreadyHasPrototype(inputTable, prototype) then return inputTable end
    for key, value in next, prototype, nil do
        inputTable[key] = copyTable(value)
    end
    return inputTable
end
local function addPrototypeToTable(inputTable, prototype)
    for key, value in next, prototype, nil do
        inputTable[key] = inputTable[key] or copyTable(rawget(prototype, key))
    end
    inputTable._prototypes[#inputTable._prototypes + 1] = prototype
    return inputTable
end

local Prototype = {}
local Prototype_mt = {
    __index = function(self, key)
        local prototypes = self._prototypes
        for i = 1, #prototypes do
            local prototype = prototypes[i]
            local value = prototype[key]
            if value ~= nil then return value end
        end
        return Prototype[key]
    end
}

function Prototype:addPrototypes(prototypes)
    local self = self or {}
    self._prototypes = self._prototypes or {}
    for i = 1, #prototypes do
        local prototype = prototypes[i]
        if not tableAlreadyHasPrototype(self, prototype) then
            addPrototypeToTable(self, prototype)
        end
    end
    return setmetatable(self, Prototype_mt)
end
function Prototype:initializeWithPrototypes(prototypes)
    local prototypes = prototypes or self._prototypes
    for i = #prototypes, 1, -1 do
        initializeTableWithRespectToPrototype(self, prototypes[i])
    end
    return self
end
function Prototype:getPrototypes()
    return self._prototypes
end

return Prototype