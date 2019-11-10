local setmetatable = setmetatable

local function copyTableWithoutFunctions(input, seen)
    if type(input) ~= "table" then return input end
    local seen = seen or {}
    if seen[input] then return seen[input] end
    local output = {}
    seen[input] = output
    for key, value in next, input, nil do
        if type(value) ~= "function" or key == "get" or key == "set" then
            output[copyTableWithoutFunctions(key, seen)] = copyTableWithoutFunctions(value, seen)
        end
    end
    return setmetatable(output, getmetatable(input))
end

local Proxy = {}
function Proxy:new(fields, initialValues)
    local copiedFields = copyTableWithoutFunctions(fields)
    local outputMetatable = {
        __index = function(t, k)
            local field = copiedFields[k]
            if field ~= nil then
                if type(field) == "table" then
                    if field.get then return field:get() end
                end
                return field
            end
            return fields[k]
        end,
        __newindex = function(t, k, v)
            local field = copiedFields[k]
            if field ~= nil then
                if type(field) == "table" then
                    if field.set then return field:set(v) end
                end
                copiedFields[k] = v
            end
        end
    }
    local output = setmetatable({}, outputMetatable)
    for key, value in pairs(initialValues) do
        output[key] = value
    end
    return output
end

local Walker = {}
Walker.speed = 5
Walker.ayylmao = { get = function(self) return 29 end }
function Walker:walk() print("walking at speed: " .. self.speed) end

local Runner = {}
Runner.speed = 10
function Runner:run() print("running at speed: " .. self.speed) end

local test1 = Proxy:new(Walker, {
    speed = 7
})

--test1:run()
test1:walk()
test1.speed = 15
test1:walk()
print(test1.ayylmao)
--test1:run()
--test1:walk()

return Prototype