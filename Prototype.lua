local setmetatable = setmetatable
local rawget = rawget
local rawset = rawset
local table = table

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

local Prototype = {}

function Prototype:new(fields)
    for fieldName, field in pairs(fields) do
        if type(field) == "table" then
            if field.from then
                local fromKeys = splitStringByPeriods(field.from)
                local numberOfFromKeys = #fromKeys

                local root = fields[fromKeys[1]]
                local outputKey = 1
                local output = root
                for i = 2, numberOfFromKeys do
                    root = output
                    outputKey = fromKeys[i]
                    output = output[outputKey]
                end

                if type(output) == "function" then
                    fields[fieldName] = function(self) return output(root) end
                else
                    field.get = function(self) return output end
                    field.set = function(self, value) root[outputKey] = value end
                end
            end
        end
    end

    function fields:new(parameters)
        local parameters = parameters or {}
        local copiedFields = copyTable(fields)

        local newInstance = {}

        setmetatable(newInstance, {
            __index = function(t, k)
                local field = copiedFields[k]
                if field ~= nil then
                    if type(field) == "table" then
                        if field.get then
                            return field:get()
                        end
                    end
                    return field
                end
                --return rawget(t, k)
            end,
            __newindex = function(t, k, v)
                local field = copiedFields[k]
                if field ~= nil then
                    if type(field) == "table" then
                        if field.set then
                            return field:set(v)
                        end
                    end
                    copiedFields[k] = v
                end
                --rawset(t, k, v)
            end
        })

        --function newInstance:initialize()
        --    for k, v in pairs(parameters) do
        --        newInstance[k] = v
        --    end
        --end

        --newInstance:initialize()
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

local RunnerAndWalker = {}
RunnerAndWalker.walker = Walker:new()
RunnerAndWalker.runner = Runner:new()
RunnerAndWalker.speed = { from = "runner.speed" }
RunnerAndWalker.run = { from = "runner.run" }
RunnerAndWalker.walk = { from = "walker.walk" }
RunnerAndWalker = Prototype:new(RunnerAndWalker)

local test1 = RunnerAndWalker:new()

--test1.runner:run()
test1:run()
test1.speed = 15
test1:run()
test1:walk()

return Prototype