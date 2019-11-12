local setmetatable = setmetatable
local getmetatable = getmetatable
local pairs = pairs
local type = type
local next = next

local function deepCopy(input, seen)
    if type(input) ~= "table" then return input end
    local seen = seen or {}
    if seen[input] then return seen[input] end
    local output = {}
    seen[input] = output
    for key, value in next, input, nil do
        output[deepCopy(key, seen)] = deepCopy(value, seen)
    end
    return setmetatable(output, deepCopy(getmetatable(input), seen))
end
local function implementPrototypesWithCompositionAndMethodForwarding(fields)
    local prototypes = fields.prototypes
    if not prototypes then return end
    for i = 1, #prototypes do
        local prototypeName = prototypes[i][1]
        local prototype = prototypes[i][2]
        fields[prototypeName] = prototype
        for fieldName, field in pairs(prototype) do
            if not fields[fieldName] then
                fields[fieldName] = { from = { prototypeName, fieldName } }
            end
        end
    end
    fields.prototypes = nil
end
local function getAccessor(t, keys)
    if type(keys) == "table" then
        local numberOfKeys = #keys
        local rootTable = t
        for i = 1, numberOfKeys - 1 do
            rootTable = rootTable[keys[i]]
        end
        return rootTable, keys[numberOfKeys]
    else
        return t, keys
    end
end
local function convertMethodForwardsToGettersAndSetters(fields)
    for fieldName, field in pairs(fields) do
        if type(field) == "table" and field.from then
            local fromKeys = field.from
            fields[fieldName] = {
                get = function(self, field)
                    local rootTable, accessKey = getAccessor(self, fromKeys)
                    return rootTable[accessKey]
                end,
                set = function(self, field, v)
                    local rootTable, accessKey = getAccessor(self, fromKeys)
                    rootTable[accessKey] = v
                end
            }
        end
    end
end
local function createProxy(fields)
    implementPrototypesWithCompositionAndMethodForwarding(fields)
    convertMethodForwardsToGettersAndSetters(fields)
    local proxyMetatable = {
        private = deepCopy(fields),
        __index = function(t, k)
            local private = getmetatable(t).private
            local field = private[k]
            if type(field) == "table" and field.get then
                return field.get(t, field)
            end
            return field
        end,
        __newindex = function(t, k, v)
            local private = getmetatable(t).private
            local field = private[k]
            if type(field) == "table" and field.set then
                field.set(t, field, v)
            end
            private[k] = v
        end,
        __pairs = function(t)
            local private = getmetatable(t).private
            return function(t, k)
                local prototypeKey = next(private, k)
                return prototypeKey, t[prototypeKey]
            end, t, nil
        end
    }
    return setmetatable({}, proxyMetatable)
end

return {
    new = function(self, fields)
        function fields:new()
            return createProxy(self)
        end
        return fields
    end
}