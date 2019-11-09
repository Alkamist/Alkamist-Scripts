local setmetatable = setmetatable
local rawget = rawget
local rawset = rawset
local table = table
local next = next
local pairs = pairs

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
local function splitStringByPeriods(str)
    local output = {}
    for piece in string.gmatch(str, "([^.]+)") do
        table.insert(output, piece)
    end
    return output
end
local function implementFieldFromKeys(str, fieldName, field, fields)
    local fromKeys = splitStringByPeriods(str)
    local output = fields[fromKeys[1]]
    local outputKey = 1
    local root
    for i = 2, #fromKeys do
        root = output
        outputKey = fromKeys[i]
        print(outputKey)
        output = output[outputKey]
    end

    if type(output) == "function" then
        fields[fieldName] = function(self) return output(root) end
    else
        field.get = function(self) return output end
        field.set = function(self, value) root[outputKey] = value end
    end
end

local Prototype = {}

function Prototype:implement(prototypes)
    local output = {}

    for i = 1, #prototypes do
        local prototype = prototypes[i]
        local member = prototype:new()
        output[member] = member
        for fieldName, field in pairs(member) do
            if fieldName ~= "initialize" and fieldName ~= "new" then
                if type(field) == "function" then
                    output[fieldName] = function(self) return output[member][fieldName](output[member]) end
                else
                    output[fieldName] = {
                        get = function(self) return field end,
                        set = function(self, value) output[member][fieldName] = value end
                    }
                end
            end
        end
    end

    return output
end

function Prototype:new(fields)
    for fieldName, field in pairs(fields) do
        if type(field) == "table" and field.from then
            implementFieldFromKeys(field.from, fieldName, field, fields)
        end
    end

    function fields:new(parameters)
        local parameters = parameters or {}
        local copiedFields = copyTable(fields)

        local newInstance = {}
        local function getField(t, k)
            local field = copiedFields[k]
            if field ~= nil then
                if type(field) == "table" then
                    if field.get then return field:get() end
                end
                return field
            end
            return rawget(t, k)
        end
        local function setField(t, k, v)
            local field = copiedFields[k]
            if field ~= nil then
                if type(field) == "table" then
                    if field.set then return field:set(v) end
                end
                copiedFields[k] = v
            end
            rawset(t, k, v)
        end
        local wentThroughAllInstanceKeys = false
        local function getNext(t, k)
            local outputKey = k
            if not wentThroughAllInstanceKeys then
                outputKey = next(t, k)
                if outputKey == nil then wentThroughAllInstanceKeys = true end
            end
            if wentThroughAllInstanceKeys then
                outputKey = next(copiedFields, outputKey)
            end
            return outputKey
        end

        local newInstance_mt = {
            __index = function(t, k) return getField(t, k) end,
            __newindex = function(t, k, v) return setField(t, k, v) end,
            __pairs = function(t)
                wentThroughAllInstanceKeys = false
                return getNext, t, nil
            end
        }
        setmetatable(newInstance, newInstance_mt)

        function newInstance:initialize()
            for k, v in pairs(parameters) do
                newInstance[k] = v
            end
        end

        newInstance:initialize()
        return newInstance
    end

    return fields
end

local Walker = {}
Walker.speed = 5
function Walker:walk() print("walking at speed: " .. self.speed) end
Walker = Prototype:new(Walker)

local Runner = {}
Runner.speed = 10
function Runner:run() print("running at speed: " .. self.speed) end
Runner = Prototype:new(Runner)

local RunnerAndWalker = Prototype:implement{ Runner, Walker }
--local RunnerAndWalker = {}
--RunnerAndWalker.runner = Runner:new()
--RunnerAndWalker.walker = Walker:new()
--RunnerAndWalker.speed = { from = "walker.speed" }
--RunnerAndWalker.walk = { from = "walker.walk" }
--RunnerAndWalker.run = { from = "runner.run" }
RunnerAndWalker = Prototype:new(RunnerAndWalker)

local test1 = RunnerAndWalker:new()

--for k, v in pairs(test1) do print(k) end

test1:run()
test1:walk()
test1.speed = 15
test1:run()
test1:walk()

return Prototype