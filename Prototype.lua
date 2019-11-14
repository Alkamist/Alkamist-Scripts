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
        local private = getmetatable(prototype).private
        for fieldName, privateField in pairs(private) do
            if not fields[fieldName] then
                if type(privateField) == "function" then
                    fields[fieldName] = function(self, ...) return privateField(self[prototypeName], ...) end
                else
                    fields[fieldName] = {
                        get = function(self) return self[prototypeName][fieldName] end,
                        set = function(self, value) self[prototypeName][fieldName] = value end
                    }
                end
            end
        end
    end
    fields.prototypes = nil
end
local function createProxy(fields)
    implementPrototypesWithCompositionAndMethodForwarding(fields)
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
            if proxy.calledWhenCreated then proxy:calledWhenCreated() end
            return proxy
        end
        return fields
    end
}