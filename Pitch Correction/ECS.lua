local tiny = require("tiny")

local function addFunctionToWorldAsSystem(world, filter, fn)
    if fn then
        local system = tiny.processingSystem{
            filter = filter,
            process = fn
        }
        world:addSystem(system)
    end
end
local function initializeEntity(entity, object)
    local defaults = object:getDefaults()
    for k, v in pairs(defaults) do
        if entity[k] == nil then
            entity[k] = v
        end
    end
    return entity
end

local ECS = {}

function ECS.newWorld() return tiny.world() end
function ECS.addSystemsToWorld(world, groupOfObjects)
    local numberOfObjects = #groupOfObjects

    for i = 1, numberOfObjects do
        local object = groupOfObjects[i]
        addFunctionToWorldAsSystem(world, object.filter, object.updateState)
    end

    for i = 1, numberOfObjects do
        local object = groupOfObjects[i]
        local drawFilter = function(system, entity)
            return object.filter(system, entity) and entity.shouldDraw
        end
        addFunctionToWorldAsSystem(world, drawFilter, object.draw)
    end

    for i = 1, numberOfObjects do
        local object = groupOfObjects[i]
        addFunctionToWorldAsSystem(world, object.filter, object.updatePreviousState)
    end
end
function ECS.addEntitiesToWorld(world, groupOfEntities)
    for i = 1, #groupOfEntities do
        local entity = groupOfEntities[i]
        initializeEntity(entity, object)
    end
end