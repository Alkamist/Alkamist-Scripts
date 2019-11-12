local setmetatable = setmetatable
local rawget = rawget
local rawset = rawset
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
    return setmetatable(output, getmetatable(input))
end

--[[local function implementPrototypesWithCompositionAndMethodForwarding(fields)
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
end]]--

local function createProxy(fields)
    local copiedFields = {}
    for fieldName, field in pairs(fields) do
        if type(field) == "table" and field.new then
            copiedFields[fieldName] = field:new()
        else
            copiedFields[fieldName] = deepCopy(field)
        end
    end
    local proxyMetatable = {
        __index = function(t, k)
            local field = copiedFields[k]
            if type(field) == "table" and field.get then
                return field.get(t)
            end
            return field
        end,
        __newindex = function(t, k, v)
            local field = copiedFields[k]
            if type(field) == "table" and field.set then
                field.set(t, v)
            end
            copiedFields[k] = v
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