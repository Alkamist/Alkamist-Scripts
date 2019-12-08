local tiny = require("tiny")

local ECS = {}
local world = tiny.world()
local storedObjects = {}

local function initializeEntity(entity, object)
    local defaults = object:getDefaults()
    for k, v in pairs(defaults) do
        if entity[k] == nil then
            entity[k] = v
        end
    end
    return entity
end

function ECS.addSystem(object)
    world:clearSystems()

    storedObjects[#storedObjects + 1] = object

    local numberOfSystems = #storedObjects

    for i = 1, numberOfSystems do
        local object = storedObjects[i]
        local system = tiny.processingSystem{
            filter = function(system, entity) return object.filter(entity) end,
            process = function(system, entity, dt) object.updateState(entity, dt) end,
            onAdd = function(system, entity) initializeEntity(entity, object) end
        }
        world:addSystem(system)
    end

    for i = 1, numberOfSystems do
        local object = storedObjects[i]
        if object.draw then
            local system = tiny.processingSystem{
                filter = function(system, entity) return object.filter(entity) and entity.shouldDraw end,
                process = function(system, entity, dt) object.draw(entity, dt) end,
                onAdd = function(system, entity) initializeEntity(entity, object) end
            }
            world:addSystem(system)
        end
    end

    for i = 1, numberOfSystems do
        local object = storedObjects[i]
        local system = tiny.processingSystem{
            filter = function(system, entity) return object.filter(entity) end,
            process = function(system, entity, dt) object.updatePreviousState(entity, dt) end,
            onAdd = function(system, entity) initializeEntity(entity, object) end
        }
        world:addSystem(system)
    end
end
function ECS.addEntity(entity)
    world:addEntity(entity)
end
function ECS.update(dt)
    world:update(dt)
end

return ECS