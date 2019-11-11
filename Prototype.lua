local setmetatable = setmetatable
local pairs = pairs
local type = type

local function copyTable(input, copies)
    copies = copies or {}
    local inputType = type(input)
    local copy
    if inputType == "table" then
        if copies[input] then
            copy = copies[input]
        else
            copy = {}
            copies[input] = copy
            setmetatable(copy, copyTable(getmetatable(input), copies))
            for inputKey, inputValue in next, input, nil do
                copy[copyTable(inputKey, copies)] = copyTable(inputValue, copies)
            end
        end
    else
        copy = input
    end
    return copy
end

local function generateTableWithPrivateDataBasedOnFields(fields)
    local output = { private = {} }
    for fieldName, field in pairs(fields) do
        local fieldType = type(field)
        -- Tables need special processing.
        if fieldType == "table" then
            if fieldName ~= "prototypes" then
                -- Call a the "new" function if it is implemented.
                if field.new then
                    output.private[fieldName] = field:new(initialValues)
                -- If a default value is provided, initialize the private value to it.
                elseif field.default then
                    output.private[fieldName] = field.default
                -- Otherwise, if it's a raw table then deep copy it to the private section.
                else
                    output.private[fieldName] = copyTable(field)
                end
            end
        -- Anything other than tables and functions gets simply moved to the private section.
        elseif fieldType ~= "function" then
            output.private[fieldName] = field
        end
    end
    return output
end
local function generateProxyMetatableBasedOnFields(fields)
    return {
        __index = function(t, k)
            local field = fields[k]
            local fieldType = type(field)
            if fieldType == "table" and field.get then
                return field.get(t.private)
            elseif fieldType == "function" then
                return field
            end
            return t.private[k]
        end,
        __newindex = function(t, k, v)
            local field = fields[k]
            local fieldType = type(field)
            if fieldType == "table" and field.set then
                return field.set(t.private, v)
            end
            t.private[k] = v
        end,
        __pairs = function(t)
            local seenMembers = {}
            local wentThroughAllPrivateKeys = false
            return function(t, k)
                local prototypeKey = k
                if not wentThroughAllPrivateKeys then
                    prototypeKey = next(t.private, prototypeKey)
                    if prototypeKey then
                        seenMembers[prototypeKey] = true
                    else
                        wentThroughAllPrivateKeys = true
                    end
                end
                if wentThroughAllPrivateKeys then
                    while true do
                        prototypeKey = next(fields, prototypeKey)
                        if prototypeKey == nil then break end
                        if not seenMembers[prototypeKey] then break end
                    end
                end
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
end
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
            local output = fields[outputKey]
            if type(output) == "function" then
                fields[fieldName] = function(self) return output(self.private) end
            else
                fields[fieldName] = {
                    get = function(self) return self[rootKey][outputKey] end,
                    set = function(self, value) self[rootKey][outputKey] = value end
                }
            end
        end
    end
end
local function givePrototypeAFunctionToChangeItsDefaults(fields)
    function fields:withDefaults(defaults)
        for k, v in pairs(defaults) do
            fields[k] = v
        end
        return fields
    end
end
local function givePrototypeAFunctionToInstantiateItself(fields)
    function fields:new(defaults)
        local output = setmetatable(generateTableWithPrivateDataBasedOnFields(fields),
                                    generateProxyMetatableBasedOnFields(fields))
        if fields.initialize then fields.initialize(output, defaults) end
        return output
    end
end

return {
    new = function(self, fields)
        implementPrototypesWithCompositionAndMethodForwarding(fields)
        convertMethodForwardsToGettersAndSetters(fields)
        givePrototypeAFunctionToChangeItsDefaults(fields)
        givePrototypeAFunctionToInstantiateItself(fields)
        return fields
    end
}