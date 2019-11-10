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
    local initialValues = initialValues or {}
    local copiedFields = copyTableWithoutFunctions(fields)
    local outputMetatable = {
        __index = function(t, k)
            local field = copiedFields[k]
            if field ~= nil then
                if type(field) == "table" then
                    if field.get then return field.get(copiedFields) end
                end
                return field
            end
            return fields[k]
        end,
        __newindex = function(t, k, v)
            local field = copiedFields[k]
            if field ~= nil then
                if type(field) == "table" then
                    if field.set then return field.set(copiedFields, v) end
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

local WalkerAndRunner = {}
WalkerAndRunner.walker = Proxy:new(Walker)
WalkerAndRunner.runner = Proxy:new(Runner)
WalkerAndRunner.walk = function(self) return self.walker.walk(self.walker) end
WalkerAndRunner.speed = {
    get = function(self) return self.walker.speed end,
    set = function(self, value) self.walker.speed = value end
}

local test1 = Proxy:new(WalkerAndRunner)

--test1:run()
test1.walker:walk()
test1.speed = 15
test1.walker:walk()
--test1.runner:run()
--print(test1.walker.ayylmao)
--test1:run()
--test1:walk()

return Prototype