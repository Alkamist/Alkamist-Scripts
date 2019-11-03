local setmetatable = setmetatable
local rawget = rawget

local function copy(input, seen)
    local inputType = type(input)
    if inputType ~= "table" then return input end
    local seen = seen or {}
    if seen[input] then return seen[input] end
    local output = {}
    seen[input] = output
    for key, value in next, input, nil do
        output[copy(key, seen)] = copy(value, seen)
    end
    return setmetatable(output, getmetatable(input))
end
local function classAlreadyHasBase(class, base)
    local classBases = class._baseClasses
    if classBases == nil then return false end
    for i = 1, #classBases do
        local classBase = classBases[i]
        if classBase == base then return true end
    end
    return false
end
local function initializeClassWithRespectToBase(class, base)
    if not classAlreadyHasBase(class, base) then return class end
    for key, value in next, base, nil do
        class[key] = copy(value)
    end
    return class
end
local function addBaseToClass(class, base)
    class._baseClasses[#class._baseClasses + 1] = base
    for key, value in next, base, nil do
        class[key] = class[key] or copy(rawget(base, key))
    end
    return class
end

local Class = {}
local Class_mt = {
    __index = function(self, key)
        local bases = self._baseClasses
        for i = 1, #bases do
            local base = bases[i]
            local value = base[key]
            if value ~= nil then return value end
        end
        return Class[key]
    end
}

function Class:addBases(baseClasses)
    local self = self or {}
    self._baseClasses = self._baseClasses or {}
    for i = 1, #baseClasses do
        local base = baseClasses[i]
        if not classAlreadyHasBase(self, base) then
            addBaseToClass(self, base)
        end
    end
    return setmetatable(self, Class_mt)
end
function Class:new(baseClasses, input)
    local input = input or {}
    return Class.addBases(input, baseClasses)
end
function Class:initialize(base)
    if base then return initializeClassWithRespectToBase(self, base) end
    local bases = self._baseClasses
    for i = #bases, 1, -1 do
        initializeClassWithRespectToBase(self, bases[i])
    end
    return self
end
function Class:getBaseClasses()
    return self._baseClasses
end

return Class