local setmetatable = setmetatable
local rawget = rawget
local rawset = rawset

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

local Prototype = {}

function Prototype:new(fields)
    return {
        new = function(self, initialValues)
            local initialValues = initialValues or {}
            local copiedFields = copyTable(fields)

            local newInstance = setmetatable({}, {
                __index = function(t, k)
                    local field = copiedFields[k]
                    if field ~= nil then
                        if type(field) == "table" then
                            return field:get()
                        end
                        return field
                    end
                    return rawget(t, k)
                end,
                __newindex = function(t, k, v)
                    local field = copiedFields[k]
                    if field ~= nil then
                        if type(field) == "table" then
                            return field:set(v)
                        end
                        field = v
                    end
                    rawset(t, k, v)
                end
            })

            function newInstance:initialize()
                for k, v in pairs(initialValues) do
                    newInstance[k] = v
                end
            end

            newInstance:initialize()

            return newInstance
        end
    }
end

local Builder = Prototype:new{
    x = 7,
    y = 8,
    get = function(self) return self.x end,
    set = function(self, value) self.x = value end
}

local Test1 = Prototype:new{
    x = 1,
    y = 2,
    z = {
        x = 12341234,
        get = function(self) return self.x end,
        set = function(self, value) self.x = value end
    },
    builder = Builder:new{
        x = 20
    }
}

local test1 = Test1:new()

print(test1.builder)
test1.builder = 5
print(test1.builder)

return Prototype