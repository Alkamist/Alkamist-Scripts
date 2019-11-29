local setmetatable = setmetatable
local rawset = rawset
local type = type
local next = next

local function createProxy(object)
    local object = object or {}
    if object.getProperties ~= nil then return object end
    local properties = {}

    function object:getProperties()
        return properties
    end
    function object:getProperty(name)
        return properties[name]
    end
    function object:setProperty(name, property)
        if type(property) == "table" then
            local initialValue = object[name]
            object[name] = nil
            properties[name] = property
            object[name] = initialValue
        end
    end
    function object:removeProperty(name)
        properties[name] = nil
    end

    return setmetatable(object, {
        __index = function(t, k)
            local property = properties[k]
            if property == nil then return end
            local propertyGet = properties[k].get
            if propertyGet then return propertyGet(t) end
        end,
        __newindex = function(t, k, v)
            local property = properties[k]
            if property == nil then
                rawset(t, k, v)
                return
            end
            local propertySet = properties[k].set
            if propertySet then return propertySet(t, v) end
        end,
        __pairs = function(t)
            local wentThroughAllProperties = false
            return function(t, k)
                local fieldKey = k
                if not wentThroughAllProperties then
                    fieldKey = next(properties, fieldKey)
                    if fieldKey ~= nil then
                        return fieldKey, t[fieldKey]
                    else
                        wentThroughAllProperties = true
                    end
                end
                if wentThroughAllProperties then
                    fieldKey = next(object, fieldKey)
                    if fieldKey ~= nil then
                        return fieldKey, t[fieldKey]
                    end
                end
            end, t, nil
        end
    })
end

return {
    new = function(object)
        return createProxy(object)
    end
}