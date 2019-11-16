local setmetatable = setmetatable
local getmetatable = getmetatable
local pairs = pairs
local type = type
local next = next

local function createProxy(fields, initialValues)
    local fields = fields or {}
    local initialValues = initialValues or {}
    local proxyMetatable = {
        __index = function(t, k)
            local field = fields[k]
            if type(field) == "table" and field.get then
                return field.get(t, field)
            end
            return field
        end,
        __newindex = function(t, k, v)
            local field = fields[k]
            if type(field) == "table" and field.set
            and not (type(v) == "table" and v.set) then
                return field.set(t, v, field)
            end
            fields[k] = v
        end,
        __pairs = function(t)
            return function(t, k)
                local fieldKey = next(fields, k)
                return fieldKey, t[fieldKey]
            end, t, nil
        end
    }
    local proxy
    if getmetatable(fields) then
        proxy = fields
    else
        proxy = setmetatable({}, proxyMetatable)
    end
    for k, v in pairs(initialValues) do
        proxy[k] = v
    end
    return proxy
end

return {
    new = function(self, fields, initialValues)
        return createProxy(fields, initialValues)
    end,
    --extend = function(self, fields)
    --    if type(fields) ~= "table" then return {} end
    --    local output = {}
    --    for k, v in pairs(fields) do
    --        output[k] = {
    --            get = function(self) return fields[k] end,
    --            set = function(self, value) fields[k] = value end
    --        }
    --    end
    --    return output
    --end
}