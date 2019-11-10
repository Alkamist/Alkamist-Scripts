local setmetatable = setmetatable
local rawget = rawget
local rawset = rawset

local function splitStringByPeriods(str)
    local output = {}
    for piece in string.gmatch(str, "([^.]+)") do
        table.insert(output, piece)
    end
    return output
end
local function implementFieldFromKeys(str, fieldName, fields)
    local fromKeys = splitStringByPeriods(str)
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

local Prototype = {}

function Prototype:new(fields)
    if fields.prototypes then
        local fieldPrototypes = fields.prototypes
        for i = 1, #fieldPrototypes do
            local fieldPrototype = fieldPrototypes[i]
            local fieldPrototypeKey = tostring(fieldPrototype)
            fields[fieldPrototypeKey] = fieldPrototype
            for fieldName, field in pairs(fieldPrototype) do
                if fieldName ~= "new" then
                    fields[fieldName] = { from = fieldPrototypeKey .. "." .. fieldName }
                end
            end
        end
    end

    for fieldName, field in pairs(fields) do
        if type(field) == "table" and field.from then
            implementFieldFromKeys(field.from, fieldName, fields)
        end
    end

    function fields:new(initialValues)
        local output = { private = {} }
        for fieldName, field in pairs(fields) do
            local fieldType = type(field)
            if fieldType == "table" then
                if fieldName ~= "prototypes" then
                    if field.new then
                        output.private[fieldName] = field:new(initialValues)
                    elseif (not field.get) and (not field.set) then
                        output.private[fieldName] = {}
                        for key, value in pairs(field) do
                            output.private[fieldName][key] = value
                        end
                    end
                end
            elseif fieldType ~= "function" then
                output.private[fieldName] = field
            end
        end
        return setmetatable(output, {
            __index = function(t, k)
                local field = fields[k]
                if field ~= nil then
                    local fieldType = type(field)
                    if fieldType == "table" and field.get then
                        return field.get(t.private)
                    elseif fieldType == "function" then
                        return field
                    end
                    return t.private[k]
                end
            end,
            __newindex = function(t, k, v)
                local field = fields[k]
                if field ~= nil then
                    local fieldType = type(field)
                    if fieldType == "table" and field.set then
                        return field.set(t.private, v)
                    end
                    t.private[k] = v
                end
            end
        })
    end

    return fields
end

return Prototype