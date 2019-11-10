local setmetatable = setmetatable

local function ipairsIterate(t, i)
    i = i + 1
    local v = t[i]
    if v then return i, v end
end
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
local function splitStringByPeriods(str)
    local output = {}
    for piece in string.gmatch(str, "([^.]+)") do
        table.insert(output, piece)
    end
    return output
end
local function implementFieldFromKeys(str, fieldName, fields)
    local fromKeys = splitStringByPeriods(str)
    local root = fields
    local output = fields[fromKeys[1]]
    local outputKey = 1
    for i = 2, #fromKeys do
        root = output
        outputKey = fromKeys[i]
        output = output[outputKey]
    end
    if type(output) == "function" then
        fields[fieldName] = function(self) return output(root) end
    else
        fields[fieldName].get = function(self) return output end
        fields[fieldName].set = function(self, value) root[outputKey] = value end
    end
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
        end,
        __pairs = function(t)
            return next, copiedFields, nil
        end,
        __ipairs = function(t)
            return ipairsIterate, copiedFields, 0
        end,
    }
    local proxy = setmetatable({}, outputMetatable)
    for key, value in pairs(initialValues) do
        proxy[key] = value
    end
    return proxy
end

function Proxy:createPrototype(fields)
    local fieldPrototypes = fields.prototypes
    if fields.prototypes then
        for i = 1, #fieldPrototypes do
            local fieldPrototype = fieldPrototypes[i]
            local proxiedMember = fieldPrototype:new()
            fields[tostring(proxiedMember)] = proxiedMember
            for fieldName, field in pairs(fieldPrototype) do
                if fieldName ~= "new" then
                    fields[fieldName] = { from = tostring(proxiedMember) .. "." .. fieldName }
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
        return Proxy:new(fields, initialValues)
    end
    return fields
end

local Walker = {}
Walker.speed = 5
Walker.ayylmao = { get = function(self) return 29 end }
function Walker:walk() print("walking at speed: " .. self.speed) end
Walker = Proxy:createPrototype(Walker)

local Runner = {}
Runner.speed = 10
function Runner:run() print("running at speed: " .. self.speed) end
Runner = Proxy:createPrototype(Runner)

--local WalkerAndRunner = {}
--WalkerAndRunner.walker = Walker:new()
--WalkerAndRunner.runner = Runner:new()
--WalkerAndRunner.walk = { from = "walker.walk" }
--WalkerAndRunner.speed = { from = "walker.speed" }
--WalkerAndRunner = Proxy:createPrototype(WalkerAndRunner)

local WalkerAndRunner = {}
WalkerAndRunner.prototypes = { Runner, Walker }
WalkerAndRunner = Proxy:createPrototype(WalkerAndRunner)

local test1 = WalkerAndRunner:new()

test1:walk()
test1:run()
test1.speed = 15
test1:walk()
test1:run()

return Prototype