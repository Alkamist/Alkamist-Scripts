local setmetatable = setmetatable
local getmetatable = getmetatable
local pairs = pairs
local type = type
local next = next

local function createProxy(fields)
    local fields = fields or {}
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
            local valueIsNewField = type(v) == "table" and (v.set or v.get)
            if type(field) == "table" and field.set and not valueIsNewField then
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
    return proxy
end

return {
    new = function(self, parameters)
        local parameters = parameters or {}
        return createProxy(parameters)
    end
}