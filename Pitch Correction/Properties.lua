local setmetatable = setmetatable
local rawget = rawget
local rawset = rawset
local type = type
local next = next

local property_mt = {
    __index = function(t, k)
        local properties = rawget(t, "_properties")
        local property = properties[k]
        if property == nil then return end
        local propertyGet = property.get
        if propertyGet then return propertyGet(t) end
    end,

    __newindex = function(t, k, v)
        local properties = rawget(t, "_properties")
        local property = properties[k]
        if property == nil then
            rawset(t, k, v)
            return
        end
        local propertySet = property.set
        if propertySet then return propertySet(t, v) end
    end,

    __pairs = function(t)
        local wentThroughAllProperties = false
        return function(t, k)
            local properties = rawget(t, "_properties")
            local fieldKey = k
            if not wentThroughAllProperties then
                fieldKey = next(properties, fieldKey)
                if fieldKey ~= nil then
                    return fieldKey, properties[fieldKey]
                else
                    wentThroughAllProperties = true
                end
            end
            if wentThroughAllProperties then
                fieldKey = next(t, fieldKey)
                if fieldKey ~= nil then
                    return fieldKey, t[fieldKey]
                end
            end
        end, t, nil
    end
}

return {
    setProperty = function(t, k, v)
        setmetatable(t, property_mt)
        rawset(t, k, nil)
        if type(rawget(t, "_properties")) ~= "table" then rawset(t, "_properties", {}) end
        rawget(t, "_properties")[k] = v
    end
}