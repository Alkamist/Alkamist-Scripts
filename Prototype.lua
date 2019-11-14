local setmetatable = setmetatable
local getmetatable = getmetatable
local pairs = pairs
local type = type
local next = next
local load = load

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
local function createFunctionString(keys)
    local getter = "return function(self, ...) return "
    if type(keys) == "table" then
        local numberOfKeys = #keys
        local functionBody = {}
        for i = 1, numberOfKeys - 1 do
            functionBody[#functionBody + 1] = keys[i]
        end
        return table.concat { getter, "self.", table.concat(functionBody, "."), ":", keys[numberOfKeys], "(...)", " end" }
    else
        return table.concat{ getter, "self:", keys, " end" }
    end
end
local function createGetterString(keys)
    local getter = "return function(self, field) return "
    if type(keys) == "table" then
        local numberOfKeys = #keys
        local functionBody = {}
        for i = 1, numberOfKeys do
            functionBody[#functionBody + 1] = keys[i]
        end
        return table.concat { getter, "self.", table.concat(functionBody, "."), " end" }
    else
        return table.concat{ getter, "self.", keys, " end" }
    end
end
local function createSetterString(keys)
    local setter = "return function(self, value, field) "
    if type(keys) == "table" then
        local numberOfKeys = #keys
        local functionBody = {}
        for i = 1, numberOfKeys do
            functionBody[#functionBody + 1] = keys[i]
        end
        return table.concat { setter, "self.", table.concat(functionBody, "."), " = value end" }
    else
        return table.concat{ setter, "self.", keys, " = value end" }
    end
end
local function convertMethodForwardsToGettersAndSetters(fields)
    for fieldName, field in pairs(fields) do
        if type(field) == "table" and field.from then
            local fromKeys = field.from
            local rootTable, accessKey = getAccessor(fields, fromKeys)
            local valueOfInterest = rootTable[accessKey]
            if type(valueOfInterest) == "function" then
                fields[fieldName] = load(createFunctionString(fromKeys))()
            else
                fields[fieldName] = {
                    get = load(createGetterString(fromKeys))(),
                    set = load(createSetterString(fromKeys))()
                }
            end
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
                return field.set(t, v, field)
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
        function fields:new(defaultValues)
            local defaultValues = defaultValues or {}
            local proxy = createProxy(self)
            for k, v in pairs(defaultValues) do
                proxy[k] = v
            end
            if proxy.initialize then proxy:initialize() end
            return proxy
        end
        return fields
    end
}