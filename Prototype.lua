local setmetatable = setmetatable
local pairs = pairs
local type = type
local next = next

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

local proxyMetatable = {
    __index = function(t, k)
        local private = t.private
        local field = private[k]
        if type(field) == "table" and field.from then
            local fromKeys = field.from
            while true do
                local rootTable, accessKey = getAccessor(t, fromKeys)
                local fieldValue = rootTable[accessKey]
                if type(fieldValue) == "table" and fieldValue.from then
                    fromKeys = fieldValue.from
                else
                    if field.get then field.get(t, fieldValue) end
                    return fieldValue
                end
            end
        end
        return field
    end,

    __newindex = function(t, k, v)
        local private = t.private
        local field = private[k]
        if type(field) == "table" and field.from then
            if field.set then field.set(t, v) end
            local fromKeys = field.from
            while true do
                local rootTable, accessKey = getAccessor(t.private, fromKeys)
                local fieldValue = rootTable[accessKey]
                if type(fieldValue) == "table" and fieldValue.from then
                    if fieldValue.set then fieldValue.set(t, v) end
                    fromKeys = fieldValue.from
                else
                    rootTable[accessKey] = v
                    return
                end
            end
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

-- NO SENSE OF ORDER!
--local function implementPrototypesWithCompositionAndMethodForwarding(fields)
--    if not fields.prototypes then return end
--    for prototypeName, prototype in pairs(fields.prototypes) do
--        fields[prototypeName] = prototype
--        for fieldName, field in pairs(prototype) do
--            fields[fieldName] = { from = { prototypeName, fieldName } }
--        end
--    end
--end
--local function convertMethodForwardsToGettersAndSetters(fields)
--    for fieldName, field in pairs(fields) do
--        if type(field) == "table" and field.from then
--            local fromKeys = field.from
--            local rootKey = fromKeys[1]
--            local outputKey = fromKeys[2]
--            if type(fields[rootKey][outputKey]) == "function" then
--                fields[fieldName] = function(self) return self[rootKey][outputKey](self) end
--            else
--                fields[fieldName] = {
--                    get = function(self) return self[rootKey][outputKey] end,
--                    set = function(self, value) self[rootKey][outputKey] = value end
--                }
--            end
--        end
--    end
--end

return {
    new = function(self, fields)
        local output = {}
        --implementPrototypesWithCompositionAndMethodForwarding(fields)
        --convertMethodForwardsToGettersAndSetters(fields)
        function output:new()
            local proxy = setmetatable({ private = copyTable(fields) }, proxyMetatable)
            if proxy.initialize then proxy:initialize() end
            return proxy
        end
        return output
    end
}