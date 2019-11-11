local setmetatable = setmetatable
local pairs = pairs
local type = type

local proxyMetatable = {
    __index = function(t, k)
        local private = t.private
        local field = private[k]
        local fieldType = type(field)
        if fieldType == "table" and field.get then
            return field.get(private)
        end
        return field
    end,
    __newindex = function(t, k, v)
        local private = t.private
        local field = private[k]
        local fieldType = type(field)
        if fieldType == "table" and field.set then
            return field.set(private, v)
        end
        private[k] = v
    end,
    __pairs = function(t)
        local private = t.private
        return function(t, k)
            local prototypeKey = next(private, k)
            return prototypeKey, t[prototypeKey]
        end, t, nil
    end,
    __ipairs = function(t)
        return function(t, i)
            i = i + 1
            local v = t[i]
            if v then return i, v end
        end, t, 0
    end,
}

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
--[[local function copyTable(input, copies)
    copies = copies or {}
    local inputType = type(input)
    local copy
    if inputType == "table" then
        if copies[input] then
            copy = copies[input]
        else
            copy = {}
            copies[input] = copy
            setmetatable(copy, getmetatable(input), copies)
            for inputKey, inputValue in next, input, nil do
                copy[copyTable(inputKey, copies)] = copyTable(inputValue, copies)
            end
        end
    else
        copy = input
    end
    return copy
end]]--

local function implementPrototypesWithCompositionAndMethodForwarding(fields)
    if fields.prototypes then
        local fieldPrototypes = fields.prototypes
        for i = 1, #fieldPrototypes do
            local fieldPrototype = fieldPrototypes[i]
            fields[fieldPrototype] = fieldPrototype
            for fieldName, field in pairs(fieldPrototype) do
                if fieldName ~= "new" then
                    fields[fieldName] = { from = { fieldPrototype, fieldName } }
                end
            end
        end
    end
end
local function convertMethodForwardsToGettersAndSetters(fields)
    for fieldName, field in pairs(fields) do
        if type(field) == "table" and field.from then
            local fromKeys = field.from
            local rootKey = fromKeys[1]
            local outputKey = fromKeys[2]
            if type(fields[rootKey][outputKey]) == "function" then
                fields[fieldName] = function(self) return self[rootKey][outputKey](self) end
            else
                fields[fieldName] = {
                    get = function(self) return self[rootKey][outputKey] end,
                    set = function(self, value) self[rootKey][outputKey] = value end
                }
            end
        end
    end
end

return {
    new = function(self, fields)
        local output = {}
        --implementPrototypesWithCompositionAndMethodForwarding(fields)
        convertMethodForwardsToGettersAndSetters(fields)
        function output:new()
            return setmetatable({ private = copyTable(fields) }, proxyMetatable)
        end
        return output
    end
}